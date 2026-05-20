# Ralph Loop — Design Document

A clean-slate design for an autonomous TDD coding loop. Supersedes the current
`ralph_loop_state.json` / `ralph_memory.md` / `ralph_report.py` prototype.

---

## 1. Purpose

Drive a backlog of well-scoped engineering tasks to completion with minimal human
involvement, while keeping a hard safety boundary: the model that writes code can
never touch the machine. It only ever *proposes*; an orchestrator script executes.

The unit of work is one task from `docs/06-task-breakdown.md`, refined into a
`tasks/<ID>.md` card, implemented test-first, and merged as one commit.

## 2. Goals and non-goals

**Goals**

1. Preserve the core cycle: **write tests → confirm they fail → implement → confirm
   green → review the tests**.
2. Two-tier agents: a cloud **outer loop** (Opus-class) that refines tasks and
   accepts results; a local **inner loop** (the coder) sized to a single
   RTX PRO 6000 Blackwell (96 GB).
3. **Saturate the local card** — keep the GPU's batch full whenever refined work
   exists.
4. The coder **cannot call tools**. It emits structured *requests*; the
   orchestrator validates, optionally gates on a human, and executes. A human can
   sit outside the loop and audit every side effect.
5. The orchestrator seeds initial context but the coder can **request more**.
6. The coder runs at a **small context length** by default; the orchestrator can
   **raise the context tier** per task when a task proves complex.
7. The orchestrator can **escalate to a larger model** when the local model is
   not good enough — accepting that the local card is not saturated by that task.

**Non-goals**

- Not a chat assistant; no interactive coding sessions.
- The coder is never given shell, filesystem, or network access — not even
  sandboxed. It is a pure text function.
- Not a replacement for human merge review; it *feeds* human review, it does not
  remove it.

## 3. System overview

```
                    ┌──────────────────────────────────────┐
                    │          OUTER LOOP  (cloud)          │
                    │     Opus-class refiner / acceptor     │
                    │   backlog ──► refined task cards      │
                    │   results ◄── acceptance verdict      │
                    └───────────────┬──────────────────────-┘
                                    │ cards / verdicts
                                    ▼
      ┌────────────────────────────────────────────────────────┐
      │               ORCHESTRATOR  (the script)                │
      │  • task scheduler + KV-cache admission control           │
      │  • context-pack builder + budgeter                       │
      │  • tool executor — the ONLY component with side effects   │
      │  • model router / escalation ladder                       │
      │  • state store + append-only event log + human gate      │
      └───────┬───────────────────────────────────┬─────────────┘
              │ context pack (prompt)              │ proposed actions
              ▼                                    │ (validated, gated)
      ┌──────────────────────────┐                 │
      │    INNER LOOP  (local)   │ ───────────────-─┘
      │   Coder — RTX PRO 6000   │
      │   Blackwell, 96 GB       │
      │   pure function:         │
      │   (context) → (actions)  │
      │   no tools, no I/O       │
      └──────────────────────────┘
```

Three components, one trust boundary. The orchestrator is the only thing that
reads files, runs tests, or writes code to disk. Both agents are stateless
functions whose entire input is the prompt the orchestrator hands them.

## 4. The core cycle

Each task moves through a deterministic state machine the orchestrator owns. The
coder is invoked once per *turn*; it never holds state between turns.

```
INIT
  └─► RED_DRAFT      coder writes ONLY the tests for the task
        └─► RED_VERIFY   orchestrator runs them
              ├─ pass already ........► flag: test is vacuous → RED_DRAFT / escalate
              ├─ fails to compile/import ► RED_DRAFT (feedback: wrong failure)
              └─ fails on assertion ...► GREEN_DRAFT     (correct red)
  GREEN_DRAFT       coder writes the implementation
        └─► GREEN_VERIFY  run tests + static analysis
              ├─ green ................► REVIEW
              └─ red ..................► GREEN_DRAFT (feedback: failure output)
  REVIEW            test-quality gate (§11)
        ├─ tests weak ..................► RED_DRAFT (strengthen) 
        └─ tests sound .................► AWAITING_ACCEPTANCE
  AWAITING_ACCEPTANCE   outer loop reviews diff + tests vs. acceptance criteria
        ├─ accept ......................► ACCEPTED  → commit, tick checkbox
        └─ reject ......................► GREEN_DRAFT / RED_DRAFT with feedback
  (any phase budget exhausted) .........► ESCALATE → raise model/context tier,
                                          reset phase budgets, retry
  (frontier tier also exhausted) .......► BLOCKED → surfaced to human, loop moves on
```

Two principles make this work:

- **Red must fail for the right reason.** A test that fails because of a missing
  import proves nothing. `RED_VERIFY` distinguishes a clean assertion failure
  (proceed) from a compile/resolution error (retry).
- **The specifier verifies.** The outer loop wrote the card; it does the
  authoritative acceptance review against its own acceptance criteria. The inner
  `REVIEW` phase is a cheap local pre-filter, not the final word.

## 5. Roles

### 5.1 Outer loop — refiner / acceptor (cloud, Opus-class)

- **Refine.** Expand a one-line backlog entry into a `tasks/<ID>.md` card:
  exact files to touch, public API signatures, acceptance criteria, the tests to
  write, dependencies. Same format the project already uses.
- **Accept.** When the inner loop reports `AWAITING_ACCEPTANCE`, review the diff
  and the tests against the card's acceptance criteria. Accept, or reject with
  specific feedback.
- Runs in the cloud, off the local card. Refinement is done **ahead of demand** —
  it keeps a deep queue of refined tasks so the local card never starves (§9.5).
- Reads/writes only task cards and verdicts; it does not write product code.

### 5.2 Inner loop — coder (local, RTX PRO 6000 Blackwell 96 GB)

- A code-specialised model in the 14–32 B dense range, or a small-active-param
  MoE (e.g. a 30 B-A3B coder). Quantised to FP8/FP4 to leave headroom for KV
  cache. Exact model is a tuning choice; the design is model-agnostic.
- Served by a continuous-batching engine (vLLM or SGLang) with Blackwell support.
- Receives a context pack, emits one structured turn (§6.2). Stateless between
  turns — the orchestrator owns the transcript.
- Default context tier is small (e.g. 16 K). The orchestrator may raise it (§7.3).

### 5.3 Orchestrator (the Python script)

The only component with side effects. Responsibilities:

- Task scheduling and **KV-cache admission control** (§9.3).
- Building and budgeting **context packs** (§7).
- **Executing tool requests** — file reads, searches, test runs, patch
  application, git operations — after validation and optional human gating.
- **Model routing** — picking the tier, escalating (§8).
- **State** — the task store, the append-only event log, the human-gate queue,
  and the cross-task memory file.
- Crash-safe: every state transition is written to the event log *before* its
  side effect, or the side effect is idempotent. Worktrees + git give natural
  checkpoints, so a restart resumes mid-task.

## 6. The trust boundary and tool-mediation protocol

### 6.1 Why the coder cannot call tools

A model that emits tool calls which are executed directly is only as safe as the
model. Here the model's output is **never executed** — it is parsed as data. The
coder is reduced to a pure function `(context) → (proposed actions)`. The worst a
fully hallucinating or adversarial coder can do is propose a bad patch, which the
red/green gates, the review gate, and human acceptance all catch. This is what
lets a human stay *outside* the loop and still trust it.

### 6.2 The turn protocol

Each turn the coder emits exactly one JSON object. Output is constrained by a
**grammar** in the serving engine (vLLM guided decoding / SGLang), so malformed
output is structurally impossible — important for small models.

```jsonc
{
  "phase": "green",                       // red | green | review
  "notes": "short, bounded reasoning",
  "requests": [                            // ask the orchestrator for things
    { "kind": "read_file",  "path": "lib/features/budget/domain/x.dart" },
    { "kind": "search",     "query": "class CategoryBudgetRepository" },
    { "kind": "symbol",     "name": "BudgetService.computeMonth" },
    { "kind": "list_dir",   "path": "lib/domain/budgeting" },
    { "kind": "run_tests",  "selector": "test/domain/budgeting/x_test.dart" }
  ],
  "patch": {                               // proposed code change
    "files": [ { "path": "...", "contents": "<full file>" } ]
  },
  "submit": false,                         // true → hand off to next phase
  "escalate": null,                        // {"reason": "..."} → ask for help
  "need_context": null                     // {"reason": "...", "est_tokens": N}
}
```

A turn is normally *either* a gather turn (`requests`) *or* an act turn
(`patch` / `submit`). The orchestrator processes fields in order, feeds results
back as the next turn's context, and loops.

### 6.3 Tool catalog and policy tiers

Every tool request is classified by policy:

| Tier        | Examples                                            | Behaviour          |
|-------------|-----------------------------------------------------|--------------------|
| **auto**    | `read_file`, `search`, `symbol`, `list_dir`, `run_tests` (in worktree) | executed immediately |
| **gate**    | apply patch to protected paths (`pubspec.yaml`, CI config), add a dependency | queued for human approval |
| **deny**    | any path outside the repo worktree, network, secrets, `git push` | rejected, fed back as an error |

`run_tests` runs inside the task's isolated git worktree, never the main tree.
Patch application to ordinary source paths is `auto` *as a proposal* — it lands
in the worktree, but it is still gated by red/green + acceptance before it can
become a commit.

### 6.4 Human-in-the-loop gating

A `gate`-tier request parks the task in the **gate queue**. The worker blocks —
and crucially, a blocked worker consumes **no GPU**, so other workers fill the
batch in the meantime (§9.1). The human approves or denies asynchronously via a
CLI/TUI; the decision is logged. Acceptance can also be configured at commit/PR
granularity rather than per task, so a human can batch-approve.

## 7. Context management

### 7.1 Context packs

The orchestrator assembles a phase-specific pack for every coder turn:

- **RED pack** — the task card; interfaces of the code under test; the project's
  test conventions; one or two existing tests as worked examples; the coding-
  standards excerpt.
- **GREEN pack** — the task card; the (now-fixed) tests; the latest failing test
  + analyzer output; the interfaces; standards. The RED reasoning is dropped.
- **REVIEW pack** — the card's acceptance criteria; the diff; the tests; the
  green test output.

The orchestrator anticipates what each phase needs; `requests` cover the rest.

### 7.2 The context budget and tiers

Context length is a **per-task tier the orchestrator sets**, not a fixed server
setting. The model is served with a high `max_model_len` *capability*, but each
task is *budgeted* to a tier:

| Tier | Window | KV cost (relative) | Use                                  |
|------|--------|--------------------|--------------------------------------|
| S    | 16 K   | 1×                 | default — most tasks                  |
| M    | 32 K   | 2×                 | multi-file tasks, several retries     |
| L    | 64 K   | 4×                 | wide blast radius, dense dependencies |

KV cache is allocated per request from the actual token count, so an S-tier task
costs 1× whether or not other tasks are larger. Raising a task to L simply makes
admission control admit fewer concurrent contexts — that is the real, intended
cost of the feature (§9.3).

### 7.3 Dynamic context-length escalation

The orchestrator raises a task's tier when:

- fulfilling a `request_context` would overflow the budget even after evicting
  the lowest-priority pack items;
- the coder emits `need_context` with an estimate above the current tier;
- the coder thrashes — repeatedly re-requesting context it has already been given
  and lost;
- a heuristic trips: distinct files touched, diff size so far, dependency fan-out.

Raising the tier needs no server restart — the orchestrator just rebuilds the
pack at the new size on the next turn and re-runs admission control. When a task
needs a window beyond the local model's *trained* maximum, that is no longer a
context problem but a **model** problem → escalate (§8).

## 8. Model tiering and escalation

A ladder, cheapest first:

1. **Local-small** (default) — the coder on the 6000. Saturates the card.
2. **Local-large** (optional) — a bigger model that still fits the 96 GB at lower
   batch; used when quality, not context, is the issue.
3. **Cloud-mid** — a capable hosted model.
4. **Cloud-frontier** — Opus-class, the same family as the outer loop.

Escalation triggers:

- `GREEN_DRAFT` budget exhausted (e.g. 5 failed implementation attempts);
- `REVIEW` rejects the tests twice even at max local context;
- required context exceeds the local model's trained maximum;
- the coder emits `escalate`;
- the outer loop rejects an `AWAITING_ACCEPTANCE` result twice.

On escalation the orchestrator raises the tier, **resets the phase budgets**, and
retries the failing phase. Escalating moves *that task* off the local card. This
is explicitly accepted: a single escalated task de-saturates nothing, because the
orchestrator immediately **backfills its GPU slot** with a queued task (§9.5).
The card only truly idles if the *refined-task queue* empties — an outer-loop
throughput problem, not an escalation problem.

A task that exhausts even the frontier tier is marked **BLOCKED** with a
`BLOCKED:` reason, surfaced to the human, and the loop moves on — one hard task
never wedges the pipeline.

## 9. Saturating the Blackwell 6000

### 9.1 Separate GPU work from wall-clock work

Only **token generation** uses the GPU. Test runs (`flutter test` is ~15–20 s
here), static analysis, file I/O, git operations, and human gates do not. A
worker blocked on any of those must not hold a GPU slot. The orchestrator models
each task worker as an async state machine that occupies the GPU only while a
completion request is in flight.

### 9.2 Concurrency and continuous batching

Saturation = *the serving engine's batch is always full*. The orchestrator runs a
**pool of task workers** larger than the GPU's nominal 1× concurrency, so that
while some workers are blocked on tool calls, enough remain in generation to fill
the batch. If a fraction *b* of wall-clock is spent blocked off-GPU, the worker
pool must be oversubscribed by roughly `1 / (1 − b)` to compensate.

Continuous batching (vLLM/SGLan) packs concurrent completion requests
automatically; the orchestrator just fires them. Chunked prefill keeps decode
latency low while large context packs are prefilled. Speculative decoding is an
optional further throughput lever.

### 9.3 KV-cache admission control

VRAM after model weights and activation overhead is the **KV-cache budget**.
Admitting more concurrent contexts than the KV budget holds causes preemption and
recompute thrash, which *lowers* throughput. The orchestrator therefore tracks

```
Σ (context_tier_tokens of each in-flight task)  ≤  KV_budget_tokens
```

and only admits a task when it fits. M- and L-tier tasks consume 2×/4× the
budget, so raising a task's context tier *reduces* how many tasks run alongside
it — the saturation cost of complexity is paid here, transparently.

Illustrative only — *measure on the actual hardware*: a 30 B-class coder in FP8
leaves on the order of ~60 GB for KV; at S-tier (16 K) that is dozens of
concurrent sequences, far more than enough to saturate the card.

### 9.4 The feedback controller

A controller adjusts the worker-pool size to hit a target (batch occupancy or SM
utilisation ≈ 95 %):

- occupancy below target **and** the ready queue is non-empty → raise the
  concurrency cap;
- KV pressure or preemptions rising → lower the cap.

This adapts automatically to the mix of dense vs. MoE models, task sizes, and
how test-heavy the current batch of tasks is.

### 9.5 The starvation constraint

The local card stays saturated **only while refined tasks are queued**. This
couples the two loops: the outer loop's refinement throughput must exceed the
inner loop's consumption throughput. Mitigations:

- the outer loop refines the backlog **in batches, well ahead of demand**;
- refinement runs in the cloud and never competes for the local card;
- a low-watermark on the ready queue triggers an outer-loop refinement burst;
- escalated tasks free their GPU slot immediately for backfill — escalation never
  idles the card, an empty queue does.

## 10. State, persistence, and memory

- **Task store** (`state.sqlite`) — one record per task: `task_id`, `status`,
  `phase`, attempt counts per phase, `model_tier`, `context_tier`, worktree path,
  token spend, wall time, `last_event_seq`, `blocked_reason`.
  Statuses: `backlog → refining → ready → in_progress → awaiting_acceptance →
  accepted | escalated | blocked | failed`.
- **Event log** — append-only `(seq, ts, task_id, type, payload)`. Types:
  `context_pack_built`, `coder_turn`, `tool_request`, `tool_result`,
  `gate_requested`, `gate_decided`, `tests_run`, `patch_applied`, `escalated`,
  `accepted`, `rejected`. Because the coder is a pure function, the log makes
  every run fully **replayable and auditable** — the basis of the human-outside-
  the-loop trust model.
- **Workspaces** — one git **worktree per in-flight task**, so concurrent tasks
  never collide. Accepted tasks become one commit on the task branch; the
  worktree is then removed.
- **Memory** (`memory.md`) — distilled cross-task lessons (e.g. "`MonthKey` has no
  `<` operator, use `compareTo`"). Curated by the outer loop, injected into RED
  and GREEN packs. Append-only with periodic compaction; never raw transcript.

## 11. Failure handling and quality gates

Per-phase attempt budgets (illustrative: RED 3, GREEN 5, REVIEW 2). Exhaustion
escalates (§8).

**The test-quality gate (`REVIEW`)** — the defence against a small model writing
weak tests *and* a weak implementation that trivially passes them. Defence in
depth, cheapest gate first:

1. **Red→green coupling** — already proven by the state machine: the tests failed
   before the implementation and passed after, so they are coupled to it.
2. **Diff-mutation check (model-free, deterministic).** The orchestrator applies
   small mutations to the *new implementation* — flip a boolean, negate a sign,
   drop a clamp — and confirms a test fails for each. Reverting the implementation
   entirely must also turn the suite red. This catches hardcoded/tautological
   tests with no model involved.
3. **Coverage threshold** — enforce the card's coverage target (the budget engine
   target here is ≥ 90 %).
4. **Local reviewer pass** — the coder model, fresh context, review prompt:
   checks the tests exercise every acceptance criterion and the implementation
   does not cheat (hardcoded returns keyed to test inputs). Cheap pre-filter.
5. **Outer-loop acceptance** — authoritative; Opus-class, with the card it wrote.

Other handling: flaky tests (non-deterministic pass/fail) are detected by re-run,
quarantined, and surfaced. A `BLOCKED` task is parked, not retried forever.

## 12. Key data schemas

**Task card** — the existing `tasks/<ID>.md` format, plus machine-readable
front-matter the refiner fills: `id`, `deps`, `files_create`, `files_edit`,
`api`, `acceptance_criteria[]`, `test_specs[]`, `est_complexity`.

**Coder turn** — §6.2.

**State record / event** — §10.

## 13. Worked example

Task `M2-T08` — "move money between categories".

1. **Refine.** Outer loop expands the backlog line into a card: signature of
   `moveMoney`, files to touch, four acceptance criteria, four test specs.
2. **Admit.** Orchestrator sees the card is `ready`, KV budget has room → creates
   worktree `wt/M2-T08`, builds the RED pack at S-tier (card + `CategoryBudget`
   and repository interfaces + an example test + standards).
3. **RED.** Coder turn 1 requests an existing split-money test as a model →
   fulfilled. Turn 2 emits a patch: the test file. Orchestrator applies it to the
   worktree, runs it → fails on a missing-method assertion → **correct red**.
4. **GREEN.** GREEN pack built. Coder emits the `moveMoney` implementation →
   tests run → one failure (negative-balance case). Failure output fed back.
   Coder patch v2 → green, analyzer clean.
5. **REVIEW.** Diff-mutation check: negating the transfer sign makes a test fail
   ✓; reverting the implementation reds the suite ✓. Coverage ✓. Local reviewer:
   all four criteria covered ✓ → `AWAITING_ACCEPTANCE`.
6. **ACCEPT.** Outer loop reviews diff + tests vs. the four criteria → accept.
   Orchestrator commits `feat(domain): ... [M2-T08]`, ticks the checkbox in
   `docs/06-task-breakdown.md`, removes the worktree.
7. Throughout, while step 4's test run was off-GPU (~15 s), other workers kept
   the card's batch full.

## 14. Script module layout

```
ralph/
  __main__.py          CLI entrypoint
  config.py            typed config schema + loading
  orchestrator.py      scheduler, admission control, main loop
  outer_loop.py        refiner + acceptor (cloud client)
  inner_loop.py        per-task TDD state machine (§4)
  agent/
    coder.py           local-model client wrapper
    protocol.py        turn schema + decoding grammar (§6.2)
    context.py         context-pack builder + budgeter (§7)
  tools/
    registry.py        tool catalog + policy tiers (§6.3)
    fs.py search.py tests.py vcs.py
  models/
    router.py          tier selection + escalation ladder (§8)
    serving.py         vLLM/SGLang client, batching
  state/
    store.py           task store (sqlite)
    events.py          append-only event log
    memory.py          cross-task memory curation
  workspace.py         git worktree lifecycle
  gate.py              human-approval queue + TUI
  metrics.py           GPU / throughput / queue observability
```

## 15. Configuration surface

- Models: local model id + quantisation; escalation ladder endpoints.
- Context tiers: token sizes for S/M/L; default tier.
- Budgets: per-phase attempt limits; per-task token cap.
- Concurrency: worker-pool bounds; KV budget; controller target occupancy.
- Policy: per-tool tier overrides; protected paths; acceptance granularity
  (per-task vs. per-PR).
- Repo: backlog file, task-card dir, test command, analyze command, commit style.

## 16. Observability

Live: GPU utilisation, batch occupancy, tokens/s, KV-cache occupancy, ready-queue
depth, count of workers blocked off-GPU. Per task: phase, attempts, tiers used,
token spend, wall time. Aggregate: tasks/hour, escalation rate, acceptance
rate, mean attempts-to-green, % wall-clock the card was saturated. The event log
backs a full post-hoc replay of any task.

## 17. Open questions / future work

- **Model choice** — dense 32 B vs. small-active MoE: MoE maximises throughput
  and KV headroom; dense may give steadier quality. Decide by measurement.
- **Reviewer independence** — is a same-model fresh-context reviewer worth its
  cost, given the model-free mutation check plus outer-loop acceptance already
  exist? Possibly drop it.
- **Speculative decoding** — measure the throughput gain against the draft
  model's VRAM cost.
- **Parallel sub-tasking** — should the orchestrator split a too-large task
  itself, or always bounce it to the outer loop to re-refine?
- **Cross-task contention** — two in-flight tasks editing the same file: detect
  at admission (card `files_edit` overlap) and serialise, or merge-resolve later?
```
