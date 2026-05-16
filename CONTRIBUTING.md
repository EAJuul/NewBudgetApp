# Contributing

## Picking up a task

1. Find the lowest-numbered unchecked task in `docs/06-task-breakdown.md` whose
   dependencies are all checked.
2. Read `docs/10-agent-workflow.md` — it defines how orchestrator and coder
   agents execute tasks.
3. Read `docs/09-coding-standards.md` — every line of code must comply.
4. Read the task card in `tasks/<ID>.md`. It names the exact files to touch,
   the public API to produce, and the acceptance criteria.

## Branch naming

```
m<milestone>/<task-id>-<short-slug>
```

Examples: `m01/m1-t05-core-tables`, `m03/m3-t02-account-list-screen`

One pull request per task. The PR description must reference the task ID.

## Commit style

Conventional Commits with a task reference:

```
feat(accounts): add AccountsDao [M1-T13]
fix(budget): correct RTA calculation [M2-T05]
test(money): add edge cases for milliunits [M1-T01]
```

Types: `feat`, `fix`, `test`, `chore`, `refactor`, `docs`. Subject ≤ 72 chars.

## Local checks (must all pass before pushing)

```bash
# Re-generate code after editing any file with a part '*.g.dart'
dart run build_runner build --delete-conflicting-outputs

# Format
dart format lib test

# Static analysis
flutter analyze --fatal-infos

# Tests
flutter test
```

## Definition of Done

A task is not done until:

1. Code compiles; `build_runner` run if generated files are involved.
2. `dart format lib test` applied.
3. `flutter analyze --fatal-infos` is clean.
4. `flutter test` is green and coverage targets are met.
5. Every acceptance criterion in the task card is satisfied.
6. The checkbox in `docs/06-task-breakdown.md` is ticked.

## Further reading

| Doc | Purpose |
|---|---|
| `docs/02-architecture.md` | Layered architecture and folder rules |
| `docs/09-coding-standards.md` | Naming, money rule, layering, async |
| `docs/10-agent-workflow.md` | Agent roles and task lifecycle |
