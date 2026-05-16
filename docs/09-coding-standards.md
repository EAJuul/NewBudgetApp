# 09 — Coding Standards

These rules exist so a small LLM agent produces consistent, reviewable code.
They are enforced by `analysis_options.yaml`, by CI, and by review. **Read this
before writing any code.**

## The money rule
- Money is an `int` of milliunits, wrapped in `Money` (`core/money/money.dart`).
- **Never** use `double`, `num`, or floating-point arithmetic for money.
- Format money for display only through `CurrencyFormatter`.

## Naming & files
- Files `snake_case.dart`; types `PascalCase`; members/variables `lowerCamelCase`.
- One public class per file; the file name matches the class
  (`AccountRepository` → `account_repository.dart`).
- A test file mirrors its source: `..._test.dart` under `test/` at the same path.

## Layering (see `02-architecture.md`)
- `domain` imports neither Flutter nor Drift.
- `presentation` never imports a `data/` file or `package:drift`.
- A repository **interface** lives in `domain`; its **implementation** in `data`.
- Cross-feature imports are allowed only for domain entities / interfaces.

## Immutability
- Domain entities and value objects are immutable. Use `freezed`, except for
  `Money` / `MonthKey`, which are hand-written immutable classes with `const`
  constructors.
- No mutable public fields. A state change produces a new object via `copyWith`.

## State management (Riverpod)
- One controller per screen, written as a `@riverpod` class (code-generated).
- Providers are named `<thing>Provider`; controller classes `<Thing>Controller`.
- A controller exposes `AsyncValue<T>` for anything that loads.
- A widget reads state with `ref.watch`; it triggers actions with
  `ref.read(<provider>.notifier).<method>()`.
- No business logic in widgets — it belongs in a controller or a domain service.

## Code generation
Three generators (`drift`, `freezed`, `riverpod_generator`) all run from one
command:
```
dart run build_runner build --delete-conflicting-outputs
```
- Run it after editing any file with a `part '*.g.dart'` / `part '*.freezed.dart'`.
- Generated files are git-ignored and must never be hand-edited.
- "Missing part" analyzer errors mean the generator has not been run.

## Errors
- Repositories throw typed exceptions from `core/error/` — never a raw `Exception`.
- Controllers catch them and surface `AsyncError`; widgets render an error state.
- Validate only at boundaries (user input, file import). Trust internal calls.

## Async & null safety
- No `!` (bang) operator except on a value null-checked on the line above.
- Prefer `final`. Avoid `dynamic` — the `strict-*` analyzer flags are on.
- Every `Future` is awaited or explicitly `unawaited(...)`.

## Comments
- Default to none. Add a comment only for a non-obvious *why* — an invariant, a
  workaround, a YNAB-specific rule. Never narrate *what* the code does.
- A non-obvious domain rule may cite a doc: `// see docs/04 — Credit cards`.

## Widgets
- `const` constructors wherever possible.
- A build method longer than ~40 lines is split into smaller widgets.
- Lists use `ListView.builder`; never build a large list eagerly.

## Definition of Done (every task)
1. Code compiles; `build_runner` has been run if generated files are involved.
2. `dart format lib test` has been applied.
3. `flutter analyze --fatal-infos` is clean.
4. Tests are written per `07-testing-strategy.md`; `flutter test` is green.
5. The task card's acceptance criteria are all met.
6. The task's checkbox in `06-task-breakdown.md` is ticked.
