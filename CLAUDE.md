# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

NewBudgetApp is a local-first, cross-platform (iOS + Android) personal budgeting app built with Flutter, modelled on YNAB's zero-based budgeting method. All data lives on-device (SQLite via Drift); no server or account required.

**Status:** planning and scaffold complete; implementation starts at task M0-T01. The single source of truth for progress is `docs/06-task-breakdown.md`.

## Commands

```bash
# Install dependencies
flutter pub get

# Regenerate code after editing any file with a part '*.g.dart' / '*.freezed.dart'
dart run build_runner build --delete-conflicting-outputs

# Format
dart format lib test

# Static analysis (must be clean before any merge)
flutter analyze --fatal-infos

# All tests
flutter test

# Tests with coverage
flutter test --coverage

# Subset of tests
flutter test test/core/money          # by folder
flutter test --name "rollover"        # by test name

# Run the app
flutter run
```

Prerequisite: Flutter SDK ≥ 3.24 (Dart ≥ 3.5). Verify with `flutter --version`.

## Architecture

Three layers; **dependencies point inward only**: `presentation → domain` and `data → domain`. `domain` never imports Flutter or Drift.

- **domain** — pure Dart entities (`freezed`), value objects (`Money`, `MonthKey`), repository *interfaces* (`abstract interface class`), and business-logic services (the budget engine in `lib/domain/budgeting/`).
- **data** — the single Drift `AppDatabase` (`lib/data/database/`), table definitions, DAOs (`lib/data/daos/`), and repository *implementations* inside each feature's `data/` folder. Mappers convert Drift rows to domain entities so Drift types never leak upward.
- **presentation** — Riverpod controllers (`@riverpod` class, one per screen) and Flutter widgets. Widgets are dumb; all logic belongs in a controller or a domain service.

Data flow: `Widget → watches controller provider → BudgetService calls repository interfaces → RepositoryImpl queries DAOs → rows mapped to entities`. Drift's reactive streams push changes back automatically.

## Folder layout

```
lib/
  main.dart
  app/                    root MaterialApp, go_router, theme
  core/                   cross-cutting utilities only (money/, time/, error/, extensions/)
  data/
    database/             AppDatabase + table definitions
    daos/                 one DAO per aggregate
  domain/
    budgeting/            budget calculation engine (pure Dart)
  features/
    accounts/
      domain/             Account entity + AccountRepository interface
      data/               AccountRepositoryImpl + row↔entity mappers
      presentation/       screens, widgets, controllers
    transactions/  budget/  categories/  payees/  targets/
    reports/  import_csv/  reconciliation/  settings/  onboarding/
test/                     mirrors lib/
integration_test/         end-to-end flows
tasks/                    per-task cards (TEMPLATE.md + M0-*, M1-* already written)
docs/                     architecture and planning documents
```

## Critical rules

### Money
- **Money is never a `double`**. It is stored and computed as `int` milliunits (1 currency unit = 1000 milliunits). `$12.34` → `12340`.
- Domain code passes the `Money` value object (`core/money/money.dart`); database columns store its raw `int`.
- Display conversion happens only in `CurrencyFormatter`.

### Code generation
Three generators (Drift, Freezed, Riverpod) all run from one command: `dart run build_runner build --delete-conflicting-outputs`. Generated files (`*.g.dart`, `*.freezed.dart`) are git-ignored and must never be hand-edited.

### Layering
- A widget never imports from a `data/` folder or `package:drift`.
- A repository interface lives in `domain`; its implementation lives in `data`.
- Cross-feature imports are allowed only for domain entities / interfaces.

### State management
- One `@riverpod` controller class per screen; named `<Thing>Controller` / `<thing>Provider`.
- Controllers expose `AsyncValue<T>` for anything that loads.
- Widgets use `ref.watch` to read state; `ref.read(<provider>.notifier).<method>()` to trigger actions.

### Null safety & async
- No `!` (bang) except on a value null-checked on the prior line.
- Every `Future` is awaited or explicitly `unawaited(...)`.
- Avoid `dynamic`; the `strict-*` analyzer flags are enabled.

### Errors
Repositories throw typed exceptions from `core/error/` — never a raw `Exception`. Controllers catch and surface `AsyncError`; widgets render the error state.

## Testing rules

| Type | Location | Rule |
|---|---|---|
| Unit | `test/` mirroring `lib/` | Pure functions, value objects, budget engine |
| Repository | `test/.../data/` | **Never mock the database** — use Drift's `NativeDatabase.memory()` |
| Widget | `test/.../presentation/` | Cover loading / empty / data / error states |
| Integration | `integration_test/` | Full flows on simulator or device |

Use `mocktail` only for dependencies that are not the database (e.g. mock repository interfaces when testing a controller).

Coverage targets: budget engine ≥ 90%; `core/`, repository impls, mappers ≥ 85%; controllers ≥ 70%.

## Definition of Done (every task)

1. Code compiles; `build_runner` run if generated files involved.
2. `dart format lib test` applied.
3. `flutter analyze --fatal-infos` is clean.
4. `flutter test` is green and coverage targets are met.
5. Task card acceptance criteria all satisfied.
6. Checkbox ticked in `docs/06-task-breakdown.md`.

## Agent workflow

Tasks are executed one at a time from `docs/06-task-breakdown.md` (lowest unchecked, dependencies met). Each task has a card in `tasks/<ID>.md` listing the exact files to touch, API signatures to produce, acceptance criteria, and tests to write. Work on branch `m<NN>/<task-id>-<slug>`; open one PR per task referencing the task ID.

Commit style: Conventional Commits with task reference — e.g. `feat(accounts): add AccountsDao [M1-T13]`.

If a task card is missing information or contradicts the codebase, reply with `BLOCKED:` and the specifics — do not guess or expand scope.

## Key documentation

| Doc | Content |
|---|---|
| `docs/02-architecture.md` | Full layered architecture and folder rules |
| `docs/03-data-model.md` | Every SQLite table, money rule, date formats |
| `docs/04-budgeting-logic.md` | RTA, rollover, credit cards, AoM algorithms |
| `docs/06-task-breakdown.md` | 174 ordered tasks — progress source of truth |
| `docs/09-coding-standards.md` | All coding conventions |
| `docs/10-agent-workflow.md` | How orchestrator and coder agents execute tasks |
| `docs/11-implementor-skill.md` | Coder agent's operating manual |
