#!/usr/bin/env python3
"""
ralph_loop.py — Local Ollama LLM orchestrator for TDD-style Flutter task
implementation. Every LLM call gets a fresh context window. The agent reads
and writes ralph_memory.md to persist state across calls.

Python owns: branching, build, test, analysis, formatting, git commits.
LLM owns: code and test files only.

Usage:
    python ralph_loop.py                    # next unchecked task
    python ralph_loop.py M1-T07            # specific task
    python ralph_loop.py M1-T07 M1-T08    # multiple tasks in order
"""

from __future__ import annotations

import re
import sys
import time
import subprocess
import requests
from pathlib import Path

# ── Config ─────────────────────────────────────────────────────────────────────
ROOT          = Path(__file__).resolve().parent
MODEL         = "qwen3.5:9b"
OLLAMA_URL    = "http://localhost:11434/api/generate"
CTX_START     = 32_000
CTX_MIN       = 8_000
CTX_SHRINK    = 0.75          # multiply on OOM
MAX_FIX       = 10            # max fix rounds per phase
MAX_FILE      = 5_000         # chars per file injected into prompt
MAX_REVISIONS = 3             # max test-review revision rounds

MEMORY_FILE   = ROOT / "ralph_memory.md"
TASKS_DOC     = ROOT / "docs" / "06-task-breakdown.md"
TASK_DIR      = ROOT / "tasks"
SKILL_FILE    = ROOT / "implementor_skill.md"
REVIEWER_FILE = ROOT / "reviewer_skill.md"

_ctx = CTX_START  # mutable; shrinks on OOM


# ── Logging ────────────────────────────────────────────────────────────────────
def log(tag: str, msg: str = ""):
    ts = time.strftime("%H:%M:%S")
    line = f"[{ts}][{tag}]"
    if msg:
        line += f" {msg}"
    print(line, flush=True)


def die(msg: str):
    print(f"\n[FATAL] {msg}", file=sys.stderr, flush=True)
    sys.exit(1)


# ── Ollama client ──────────────────────────────────────────────────────────────
def llm(prompt: str, system: str = "") -> str:
    """Call Ollama with automatic OOM-triggered context shrinking."""
    global _ctx
    for attempt in range(4):
        try:
            resp = requests.post(OLLAMA_URL, json={
                "model":   MODEL,
                "prompt":  prompt,
                "system":  system,
                "stream":  False,
                "options": {
                    "num_ctx":     _ctx,
                    "temperature": 0.15,
                    "top_p":       0.9,
                },
            }, timeout=600)
            resp.raise_for_status()
            body = resp.json()

            err = body.get("error", "")
            if err:
                if any(w in err.lower() for w in ("memory", "oom", "context", "too long")):
                    _shrink_ctx()
                    continue
                die(f"Ollama error: {err}")

            text = body.get("response", "").strip()
            if not text:
                die("LLM returned an empty response")
            return text

        except requests.Timeout:
            log("warn", f"LLM timeout on attempt {attempt + 1}/4, retrying…")
            time.sleep(5)
        except requests.RequestException as exc:
            if any(w in str(exc).lower() for w in ("memory", "oom")):
                _shrink_ctx()
                continue
            die(f"LLM request failed: {exc}")

    die("LLM failed after 4 attempts")


def _shrink_ctx():
    global _ctx
    new = max(CTX_MIN, int(_ctx * CTX_SHRINK))
    if new == _ctx:
        die(f"Context at minimum ({CTX_MIN}), still OOM — cannot continue")
    log("ctx", f"OOM detected — shrinking {_ctx} → {new}")
    _ctx = new


# ── Shell helpers ──────────────────────────────────────────────────────────────
def sh(cmd: list) -> tuple:
    """Run a command, return (returncode, combined_output)."""
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT)
    return r.returncode, (r.stdout + r.stderr).strip()


def must(cmd: list) -> str:
    code, out = sh(cmd)
    if code != 0:
        die(f"`{' '.join(cmd)}` failed:\n{out}")
    return out


# ── Git ────────────────────────────────────────────────────────────────────────
def git_checkout(branch: str):
    code, _ = sh(["git", "rev-parse", "--verify", branch])
    if code == 0:
        must(["git", "checkout", branch])
        log("git", f"switched to existing branch '{branch}'")
    else:
        must(["git", "checkout", "-b", branch])
        log("git", f"created branch '{branch}'")


def git_commit(msg: str):
    sh(["git", "add", "-A"])
    code, out = sh(["git", "commit", "-m", msg])
    if code != 0 and "nothing to commit" not in out:
        die(f"git commit failed:\n{out}")
    log("git", f"committed: {msg}")


# ── Task discovery ─────────────────────────────────────────────────────────────
def find_next_task(wanted: list) -> dict | None:
    """Return the next unchecked task dict from the breakdown doc."""
    text = TASKS_DOC.read_text("utf-8")
    # Format: - [ ] **M1-T07** — description
    for m in re.finditer(r"- \[([ x])\] \*\*(M\d+-T\d+)\*\*", text):
        done = m.group(1) == "x"
        tid  = m.group(2)
        if done or (wanted and tid not in wanted):
            continue
        cards = sorted(TASK_DIR.glob(f"{tid}*.md"))
        if not cards:
            log("skip", f"No task card found for {tid}")
            continue
        return {"id": tid, "card": cards[0]}
    return None


def mark_done(tid: str):
    path = TASKS_DOC
    path.write_text(
        path.read_text("utf-8").replace(f"- [ ] **{tid}**", f"- [x] **{tid}**", 1),
        "utf-8",
    )
    log("done", f"Marked {tid} complete in docs/06-task-breakdown.md")


# ── File helpers ───────────────────────────────────────────────────────────────
def slurp(path: Path, limit: int = MAX_FILE) -> str:
    """Read a file, truncating if needed."""
    if not path.exists():
        return f"(file not found: {path.relative_to(ROOT)})"
    text = path.read_text("utf-8", errors="replace")
    if len(text) > limit:
        return text[:limit] + f"\n…[{len(text) - limit} chars omitted]"
    return text


def card_file_refs(card_text: str) -> list:
    """Extract lib/ and test/ .dart paths mentioned in the task card."""
    hits = re.findall(r'`((?:lib|test)/[^`\s]+\.dart)`', card_text)
    hits += re.findall(r'(?<![`/\w])((?:lib|test)/\S+\.dart)', card_text)
    return list(dict.fromkeys(hits))  # deduplicate, preserve order


def write_files(response: str) -> list:
    """
    Parse [FILE:rel/path.dart]...content...[/FILE] blocks from the LLM
    response and write each to disk. Returns list of written relative paths.
    """
    written = []
    for m in re.finditer(r'\[FILE:([^\]]+)\](.*?)\[/FILE\]', response, re.DOTALL):
        rel     = m.group(1).strip()
        raw     = m.group(2).strip()
        # Strip optional surrounding code fences (```dart ... ```)
        content = re.sub(r'^```[^\n]*\n', '', raw)
        content = re.sub(r'\n?```\s*$', '', content)
        dest = ROOT / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(content.rstrip() + "\n", "utf-8")
        log("write", rel)
        written.append(rel)
    return written


def update_memory(response: str):
    """Extract [MEMORY]...[/MEMORY] block and persist to ralph_memory.md."""
    m = re.search(r'\[MEMORY\](.*?)\[/MEMORY\]', response, re.DOTALL)
    if m:
        MEMORY_FILE.write_text(m.group(1).strip() + "\n", "utf-8")
        log("memory", "updated")


# ── Flutter toolchain ──────────────────────────────────────────────────────────
def build_runner() -> tuple:
    """Run build_runner. Returns (ok, output)."""
    code, out = sh([
        "dart", "run", "build_runner", "build",
        "--delete-conflicting-outputs",
    ])
    return code == 0, out


def fmt():
    sh(["dart", "format", "lib", "test"])


def test_suite(path: str = "") -> tuple:
    """Run flutter test. Returns (ok, output)."""
    cmd = ["flutter", "test"] + ([path] if path else [])
    code, out = sh(cmd)
    return code == 0, out


def analyze() -> tuple:
    """Run flutter analyze. Returns (ok, issues_list)."""
    code, out = sh(["flutter", "analyze", "--fatal-infos"])
    if code == 0:
        return True, []
    # Extract individual diagnostic lines
    issues = [
        line for line in out.splitlines()
        if " • " in line and not line.startswith("Analyzing")
    ]
    return False, (issues or [out[:2000]])


# ── Prompt builders ────────────────────────────────────────────────────────────
def _skill() -> str:
    return SKILL_FILE.read_text("utf-8") if SKILL_FILE.exists() else ""


def _reviewer_skill() -> str:
    return REVIEWER_FILE.read_text("utf-8") if REVIEWER_FILE.exists() else ""


def _memory() -> str:
    return MEMORY_FILE.read_text("utf-8") if MEMORY_FILE.exists() else "No memory yet."


def build_prompt(task: dict, instruction: str, extra: dict) -> str:
    card = slurp(task["card"], 4_000)
    parts = [
        "# Agent Memory\n", _memory(), "\n\n",
        f"# Task: {task['id']}\n", card, "\n\n",
        "# Instruction\n", instruction,
    ]
    if extra:
        parts += ["\n\n# Relevant Source Files"]
        for name, content in extra.items():
            parts += [f"\n\n## {name}\n```\n{content}\n```"]
    return "".join(parts)


# ── Agent calls ────────────────────────────────────────────────────────────────
def call_agent(task: dict, instruction: str, extra: dict = None) -> list:
    """
    Call the implementor agent with a fresh context window.
    Persists memory and writes any output files.
    Returns list of written relative file paths.
    """
    log("agent", instruction[:80].replace("\n", " "))
    prompt   = build_prompt(task, instruction, extra or {})
    response = llm(prompt, system=_skill())
    update_memory(response)
    return write_files(response)


def call_reviewer(task: dict, test_files: dict) -> str:
    """Call the reviewer agent. Returns verdict string."""
    card   = slurp(task["card"], 3_000)
    blocks = "\n\n".join(
        f"### {p}\n```dart\n{c}\n```" for p, c in test_files.items()
    )
    prompt = (
        f"# Task Card\n{card}\n\n"
        f"# Tests to Review\n{blocks}\n\n"
        "Review the tests against the task card requirements.\n"
        "Reply with exactly one of:\n"
        "  APPROVED\n"
        "  FEEDBACK: <specific issues>\n"
    )
    log("reviewer", "reviewing tests…")
    return llm(prompt, system=_reviewer_skill())


# ── Issue extractors ───────────────────────────────────────────────────────────
def first_build_error(output: str) -> str:
    lines = output.splitlines()
    for i, line in enumerate(lines):
        if re.search(r'\berror\b', line, re.IGNORECASE):
            return "\n".join(lines[i: i + 30])
    return output[:1500]


def first_test_failure(output: str) -> str:
    lines = output.splitlines()
    for i, line in enumerate(lines):
        if re.search(r'(FAILED|Expected:|══╡|package:test|^\s*Error:)', line):
            return "\n".join(lines[max(0, i - 2): i + 30])
    return output[:1500]


# ── Fix-until-clean loop ───────────────────────────────────────────────────────
def fix_until_clean(task, label, check_fn, make_instr, extra, rounds=MAX_FIX) -> bool:
    """
    Repeatedly: run check_fn() → if failing, ask agent to fix one issue →
    dart format → build_runner → repeat.

    check_fn()       → (ok: bool, data)
    make_instr(data) → instruction string for the agent
    """
    for i in range(rounds):
        ok, data = check_fn()
        if ok:
            log(f"fix-{label}", "clean!")
            return True
        n = len(data) if isinstance(data, list) else "?"
        log(f"fix-{label}", f"round {i + 1}/{rounds}  ({n} issue(s))")
        call_agent(task, make_instr(data), extra)
        fmt()
        build_runner()  # always regenerate after agent writes files
    # Final verdict after all rounds
    ok, _ = check_fn()
    return ok


# ── Task runner ────────────────────────────────────────────────────────────────
def run_task(task: dict):
    tid      = task["id"]
    card_txt = task["card"].read_text("utf-8")
    refs     = card_file_refs(card_txt)
    extra    = {p: slurp(ROOT / p) for p in refs if (ROOT / p).exists()}

    print(f"\n{'═' * 62}", flush=True)
    print(f"  {tid}  —  {task['card'].stem}", flush=True)
    print(f"{'═' * 62}", flush=True)

    # ── 1. Branch ──────────────────────────────────────────────────────────────
    # e.g. M1-T07 → m01/m1-t07[-slug-from-card-filename]
    m_tid = re.match(r'M(\d+)-T(\d+)', tid)
    num   = int(m_tid.group(1)) if m_tid else 0
    stem  = task["card"].stem  # e.g. "M1-T07" or "M1-T07-category-budgets"
    slug  = re.sub(r'^M\d+-T\d+-?', '', stem, flags=re.IGNORECASE).lower()
    branch = f"m{num:02d}/{tid.lower()}" + (f"-{slug}" if slug else "")
    git_checkout(branch)

    # ── 2. Generate tests ──────────────────────────────────────────────────────
    log("phase", "GENERATE TESTS")
    written = call_agent(task,
        "Write the test file(s) for this task. "
        "Tests must be syntactically correct but must FAIL (red phase) "
        "because the implementation does not exist yet. "
        "Use NativeDatabase.memory() for every Drift database test — never mock the DB. "
        "Output ONLY test files (no implementation files).",
        extra,
    )
    test_files = {
        p: (ROOT / p).read_text("utf-8")
        for p in written
        if p.startswith("test/")
    }

    if not test_files:
        log("warn", "Agent wrote no test files; skipping review phase")

    # ── 3. Review tests ────────────────────────────────────────────────────────
    if test_files:
        log("phase", "REVIEW TESTS")
        for rev in range(MAX_REVISIONS):
            verdict = call_reviewer(task, test_files)
            log("review", verdict[:160].replace("\n", " "))
            if verdict.upper().lstrip().startswith("APPROVED"):
                break
            log("review", f"feedback received — revision round {rev + 1}")
            written2 = call_agent(task,
                f"Revise the test files based on this reviewer feedback:\n\n{verdict}\n\n"
                "Output ONLY the revised test files.",
                {**extra, **test_files},
            )
            new_tests = {
                p: (ROOT / p).read_text("utf-8")
                for p in written2
                if p.startswith("test/")
            }
            if new_tests:
                test_files = new_tests

    # ── 4. Verify tests are red ────────────────────────────────────────────────
    log("phase", "VERIFY TESTS RED")
    fmt()
    _, test_out = test_suite()
    if "All tests passed" in test_out and "FAILED" not in test_out:
        log("warn", "Tests pass before any implementation — they may be vacuous")
    else:
        log("ok", "Tests fail as expected (red phase confirmed)")

    # ── 5. Implement ───────────────────────────────────────────────────────────
    log("phase", "IMPLEMENT")
    call_agent(task,
        "Implement the task to make the tests pass. "
        "Write ONLY implementation files (do not touch test files). "
        "Satisfy every acceptance criterion in the task card.",
        {**extra, "[test_output_snippet]": test_out[:2000]},
    )

    # ── 6. Build loop ──────────────────────────────────────────────────────────
    log("phase", "BUILD")
    fmt()
    ok = fix_until_clean(
        task, "build", build_runner,
        lambda out: (
            f"Fix this build error (one issue at a time):\n\n"
            f"```\n{first_build_error(out)}\n```"
        ),
        extra,
    )
    if not ok:
        die(f"Could not fix build errors for {tid} after {MAX_FIX} rounds")

    # ── 7. Test loop ───────────────────────────────────────────────────────────
    log("phase", "TESTS")
    ok = fix_until_clean(
        task, "test", test_suite,
        lambda out: (
            f"Fix this failing test (one at a time):\n\n"
            f"```\n{first_test_failure(out)}\n```"
        ),
        extra,
    )
    if not ok:
        die(f"Could not fix test failures for {tid} after {MAX_FIX} rounds")

    # ── 8. Analysis loop ───────────────────────────────────────────────────────
    log("phase", "ANALYZE")
    ok = fix_until_clean(
        task, "analyze", analyze,
        lambda issues: (
            f"Fix this analyzer warning (one issue at a time):\n\n"
            f"```\n{issues[0]}\n```"
        ),
        extra,
    )
    if not ok:
        die(f"Could not fix analysis issues for {tid} after {MAX_FIX} rounds")

    # ── 9. Commit ───────────────────────────────────────────────────────────────
    log("phase", "COMMIT")
    fmt()
    git_commit(f"feat: implement {tid} [{tid}]")
    mark_done(tid)
    print(f"\n  ✓  {tid} complete!\n", flush=True)


# ── Entry point ────────────────────────────────────────────────────────────────
def main():
    wanted = sys.argv[1:]

    if not (ROOT / "pubspec.yaml").exists():
        die("Must be run from the Flutter project root (pubspec.yaml not found)")

    # Verify Ollama is reachable before starting
    try:
        requests.get("http://localhost:11434/api/version", timeout=5).raise_for_status()
    except Exception as exc:
        die(
            f"Cannot reach Ollama at localhost:11434 — is it running?\n"
            f"Start it with: ollama serve\n({exc})"
        )
    log("ralph-loop", f"model={MODEL}  ctx={_ctx}  project={ROOT.name}")

    processed: set = set()
    while True:
        remaining = [t for t in wanted if t not in processed] if wanted else []
        task = find_next_task(remaining)
        if not task:
            log("done", "No more tasks to process" if not wanted else
                         f"All requested tasks complete: {', '.join(wanted)}")
            break
        run_task(task)
        processed.add(task["id"])
        if wanted and all(t in processed for t in wanted):
            break


if __name__ == "__main__":
    main()
