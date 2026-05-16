# <ID> — <Title>

> Copy this file to `tasks/<ID>.md` and fill in every section. Keep it small —
> a card must fit one small-context LLM session (≤ ~200 lines of new code plus
> its tests). If it will not fit, split it. See `docs/10-agent-workflow.md`.

- **Milestone:** M<N>
- **Status:** tracked in `docs/06-task-breakdown.md` (single source of truth)
- **Dependencies:** <task IDs that must be checked off first, or "none">
- **Estimated new code:** <S ≤ 80 / M ≤ 150 / L ≤ 200 lines>

## Goal
<One or two sentences: what this task delivers and why.>

## Context — read first
- `docs/09-coding-standards.md`
- `docs/10-agent-workflow.md`
- <other relevant doc section(s), e.g. "docs/03-data-model.md — accounts table">

## Files
Create:
- `<path>` — <purpose>

Edit:
- `<path>` — <what changes>

Do **not** touch any other file.

## Public API to produce
```dart
<exact signatures: class names, method signatures, fields. The coder
implements these and nothing more — no extra public members.>
```

## Implementation notes
- <constraints, algorithms, gotchas, references to docs/04 etc.>

## Tests to write
File: `test/<mirrored path>_test.dart`
- <test case>
- <edge cases: zero, negative, boundaries>

## Acceptance criteria
- [ ] <observable, checkable outcome>
- [ ] `dart format lib test`, `flutter analyze --fatal-infos`, `flutter test`
      all pass.
- [ ] The Definition of Done in `docs/09-coding-standards.md` is satisfied.
- [ ] This task's checkbox in `docs/06-task-breakdown.md` is ticked.
