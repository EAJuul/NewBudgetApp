# 07 — Testing Strategy

Testing is non-negotiable: a small LLM writes most of the code, so tests are how
we know it works. Every task's Definition of Done includes tests.

## Test types & where they live
| Type | Tool | Location | Tests what |
|---|---|---|---|
| Unit | `flutter_test` | `test/` mirroring `lib/` | Value objects, the budget engine, mappers, pure functions |
| Repository | `flutter_test` + Drift in-memory | `test/.../data/` | DAOs & repository impls against a real (in-memory) SQLite |
| Widget | `flutter_test` | `test/.../presentation/` | A widget's loading / empty / data / error states |
| Integration | `integration_test` | `integration_test/` | Full user flows on a simulator or device |

A test file mirrors its source: `lib/core/money/money.dart` →
`test/core/money/money_test.dart`.

## Coverage targets (reported by CI, enforced by review)
- `lib/domain/budgeting/` (the budget engine): **≥ 90%** line coverage.
- `lib/core/`, all repository implementations, all mappers: **≥ 85%**.
- Controllers: **≥ 70%**.
- Widgets: at least one widget test per screen state; no line target.

## Unit tests
Pure functions get exhaustive case tables. `Money`, `MonthKey`,
`advance(date, frequency)`, and every budget-engine function must cover edge
cases: zero, negative, large values, month boundaries, and leap years.

## Repository tests use a real database
**Never mock the database.** Drift provides an in-memory SQLite
(`NativeDatabase.memory()`); repository tests run against it. This catches
schema, query, and mapping bugs that a mock would hide.
```dart
late AppDatabase db;
setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
tearDown(() => db.close());
```

## Mocking
Use `mocktail` only for dependencies that are **not** the database — e.g. when
testing a controller, mock the repository *interface*. Domain interfaces exist
partly to make this easy.

## Widget tests
Pump each screen inside `ProviderScope(overrides: [...])` with fake controllers,
then assert on each state (loading / empty / data / error). Use `mocktail` fakes
for a controller's dependencies.

## Budget-engine fixtures
Task `M2-T01` builds a `BudgetFixture` helper that constructs a known set of
accounts / categories / transactions in memory. Engine tests assert exact
milliunit results against hand-computed expected values. This fixture is the
single most important test asset in the project.

## Migration tests
When the Drift schema version increases, export the schema
(`dart run drift_dev schema dump`) and add a migration test that upgrades from
the previous version and verifies that data survives.

## Definition of Done — testing portion
A task is not done unless:
- New public functions / classes have unit tests; new screens have widget tests.
- `flutter test` passes locally.
- Coverage for the touched area meets the target above.
- No test is skipped (`skip:`) without a written reason.

## Running tests
```
flutter test                    # all tests
flutter test --coverage          # writes coverage/lcov.info
flutter test test/core/money     # one folder
flutter test --name "rollover"   # by test name
```
