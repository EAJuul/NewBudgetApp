# 02 — Architecture

## Tech stack

| Concern | Choice | Why |
|---|---|---|
| Language / UI | Dart + Flutter (Material 3) | One codebase for iOS + Android. |
| State management | Riverpod 2 (+ `riverpod_generator`) | Compile-safe, testable without a widget tree, low boilerplate. |
| Persistence | Drift over SQLite | Type-safe SQL, reactive `Stream` queries, real migrations, in-memory DB for tests. |
| Navigation | `go_router` | Declarative, deep-linkable routes. |
| Immutable models | `freezed` | Generated `==`, `copyWith`, unions — removes a class of hand-written bugs. |
| Charts | `fl_chart` | Reports milestone (M9). |
| Import | `file_picker` + `csv` | CSV import milestone (M8). |
| Tests | `flutter_test`, `integration_test`, `mocktail` | See `07-testing-strategy.md`. |
| CI/CD | GitHub Actions | See `08-ci-cd.md`. |

The stack is chosen deliberately for an LLM-driven build: each tool has a large
training corpus and strong compile-time checking. Most code is written by a
small model — **the compiler and the code generators are the safety net.**

## Layered architecture
Three layers. **Dependencies point inward only.** The rule is
`presentation → domain` and `data → domain`. `domain` depends on nothing.

```
┌───────────────────────────────────────────────┐
│ presentation   features/*/presentation         │  Widgets, screens,
│                Riverpod controllers/providers   │  go_router routes
├───────────────────────────────────────────────┤
│ domain         features/*/domain  +  domain/    │  Entities, value objects,
│                repository INTERFACES,           │  pure business logic.
│                services (the budget engine)     │  No Flutter, no Drift.
├───────────────────────────────────────────────┤
│ data           features/*/data  +  data/        │  Drift DB, tables, DAOs,
│                repository IMPLEMENTATIONS        │  mappers (row ↔ entity)
└───────────────────────────────────────────────┘
```

- **domain** is pure Dart: entities (`freezed`), value objects (`Money`,
  `MonthKey`), repository **interfaces** (`abstract interface class
  AccountRepository`), and services holding business logic (the budget
  calculation engine). It imports no Flutter and no Drift. It is the most
  heavily unit-tested layer.
- **data** holds the Drift database, table definitions, DAOs, and the
  **implementations** of the domain repository interfaces. Mappers convert
  Drift rows to domain entities so Drift types never leak upward.
- **presentation** holds Riverpod controllers and Flutter widgets. Controllers
  call repository interfaces and services; widgets are dumb and render
  controller state.

The payoff: when sync is added post-MVP, only the `data` layer changes.

## Folder structure
Feature-first, so a coding task touches exactly one feature folder.

```
lib/
  main.dart                  app entry
  app/
    app.dart                 root MaterialApp
    router.dart              go_router config (created in M0-T05)
    theme.dart               Material 3 theme
  core/                      cross-cutting utilities — no feature logic
    money/                   Money value object, CurrencyFormatter
    time/                    MonthKey, date helpers
    error/                   typed failures/exceptions
    extensions/
  data/
    database/                AppDatabase + table definitions (one shared DB)
    daos/                    one DAO per aggregate
  domain/
    budgeting/               the budget calculation engine (pure Dart)
  features/
    accounts/
      domain/                Account entity + AccountRepository interface
      data/                  AccountRepositoryImpl + row↔entity mappers
      presentation/          screens, widgets, controllers
    transactions/  budget/  categories/  payees/  targets/
    reports/  import_csv/  reconciliation/  settings/  onboarding/
test/                        unit + widget tests, mirrors lib/
integration_test/            end-to-end flows
```

Rules for the layout:

- A domain **entity** and its **repository interface** live in their owning
  feature's `domain/` folder. Other features may import an entity directly
  (e.g. `transactions` imports `features/accounts/domain/account.dart`).
- There is **one shared Drift database** in `data/database/`. DAOs live in
  `data/daos/`. A feature's repository **implementation** lives in that
  feature's `data/` folder and talks to the shared DAOs.
- The **budget engine** is cross-feature and pure, so it lives in
  `domain/budgeting/`, not inside one feature.
- `core/` is pure utilities only — never feature logic.

## Data flow (read example: the budget screen)
```
BudgetScreen (widget)
  └ watches budgetControllerProvider (Riverpod)
       └ BudgetController calls BudgetService.computeMonth(monthKey)
            └ BudgetService reads CategoryRepository + TransactionRepository
                 └ *RepositoryImpl query Drift DAOs → rows
                      └ mappers turn rows into domain entities
       └ BudgetService returns a pure MonthBudget entity
  └ widget renders MonthBudget
```
Writes go the other way: widget → controller method → repository interface →
DAO → Drift. Drift's reactive streams then push the change back so dependent
screens refresh automatically.

## Cross-cutting rules (enforced in review and CI)
- **Money is never a `double`.** It is an `int` of *milliunits* (1/1000 of a
  currency unit) wrapped in the `Money` value object. See `03-data-model.md`.
- A widget never imports from a `data/` folder or from `package:drift`.
- A repository interface lives in `domain`; its implementation lives in `data`.
- Every domain service and value object has a unit test. Every widget has a
  widget test covering its loading / empty / data / error states.
- Generated files (`*.g.dart`, `*.freezed.dart`) are not committed;
  `build_runner` regenerates them locally and in CI.
