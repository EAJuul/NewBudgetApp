# 10 — Agent Workflow

This document tells the agents that build the app how to work. There are two
roles; they may be one model in a loop or two different models.

## Roles
- **Orchestrator** — picks the next task, expands it into a full task card,
  hands it off, then verifies and integrates the result. Needs the whole repo
  in view but writes little code. A larger model is a good fit.
- **Coder** — implements exactly one task card. Designed to run with a **small
  context window** (e.g. Qwen3 8B). It loads only what its card lists. Its
  operating manual is the implementor skill in `docs/11-implementor-skill.md` —
  load that as the agent's system prompt.

## The task card
Every task is described by a card based on `tasks/TEMPLATE.md`. Cards live in
per-milestone folders — `tasks/M0/M0-T01.md`, `tasks/M1/M1-T13.md`, etc.
Detailed cards already exist for all of M0, M1, M2, and M3. For every other
task the orchestrator creates the card from the one-line entry in
`06-task-breakdown.md` **before** handing it to a coder.

A card is self-contained: it names the files to create/edit, the exact public
API to produce, the dependency tasks (already done), the acceptance criteria,
and the tests to write. A coder should never need more than: this document,
`09-coding-standards.md`, the card, and the few files the card names.

## Task lifecycle
```
1. Orchestrator picks the lowest-numbered unchecked task whose deps are all done.
2. Orchestrator expands it into tasks/M<NN>/<ID>.md from the template.
3. Coder reads: 09-coding-standards.md + this doc + the card + the listed files.
4. Coder implements code + tests on a branch m<NN>/<id>-<slug>.
5. Coder runs: build_runner (if needed) -> dart format lib test ->
   flutter analyze --fatal-infos -> flutter test. All must pass.
6. Coder opens a pull request referencing the task ID.
7. CI runs ci.yml. If red, the coder fixes and pushes again.
8. Orchestrator reviews against the card's acceptance criteria, merges, and
   ticks the checkbox in 06-task-breakdown.md.
```

## Context discipline for the coder
- Load only the files the card lists. Do not explore the repo.
- If a needed file or API is missing, the card is wrong — **stop and report**.
  Do not invent it and do not expand scope.
- Implement only this task. No refactoring of neighbouring code, no extra
  features, no "while I'm here" changes.
- Keep output small: if a task seems to need more than ~200 lines of new code,
  it is too big — report back so the orchestrator can split it.

## Expanding a task into a card (orchestrator)
For a one-line entry in `06-task-breakdown.md`:
1. Copy `tasks/TEMPLATE.md` to `tasks/M<NN>/<ID>.md` (creating the milestone
   folder if it does not yet exist).
2. Fill in: goal; exact file paths; the public API signatures to produce;
   dependencies; acceptance criteria; the test cases to write; pointers to the
   relevant doc sections.
3. Confirm every dependency task is checked off in `06-task-breakdown.md`.
4. Keep it small. Split if needed and record the sub-IDs in the breakdown.

## When the coder is blocked
Write a `BLOCKED:` note in the pull request (or the task card) stating exactly
what is missing or contradictory, then stop. The orchestrator fixes the card or
inserts a prerequisite task. Never guess past a contradiction.

## Status tracking
`06-task-breakdown.md` is the **single source of truth** for progress. An
unchecked box is not done; a checked box is done and merged. Do not track
status anywhere else.

## Definition of Done
A task is done when every item in the Definition of Done list in
`09-coding-standards.md` is satisfied and the card's acceptance criteria pass.

## Quick reference — handoff prompt for a coder
> Implement task `<ID>`. Read `tasks/M<NN>/<ID>.md`, `docs/09-coding-standards.md`,
> `docs/10-agent-workflow.md`, and `docs/11-implementor-skill.md`. Touch only
> the files the card lists. Write
> the code and the tests. Run `build_runner`, `dart format lib test`,
> `flutter analyze --fatal-infos`, and `flutter test` — all must pass. If the
> card is missing information or contradicts the codebase, reply with
> `BLOCKED:` and the specifics instead of guessing.
