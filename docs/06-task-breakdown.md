# 06 — Task Breakdown

This is the **authoritative, ordered task list** and the **single source of
truth for progress**. An unchecked box is not done; a checked box is done and
merged.

## Task system
- **Task ID:** `M<milestone>-T<nn>` — e.g. `M1-T05`.
- **Granularity:** each task is sized for one small-context LLM session — at
  most ~200 lines of new code plus its tests. If a task turns out larger, split
  it (`M4-T05a`, `M4-T05b`) and note it here.
- **Detailed cards:** full task cards exist in `tasks/` for all of M0, M1, and
  M2. For every remaining task (M3 onward) the orchestrator expands the
  one-line entry below into `tasks/<ID>.md` using `tasks/TEMPLATE.md` before
  handing it to a coder. See `10-agent-workflow.md`.
- **Definition of Done:** see `09-coding-standards.md`. In short — compiles,
  formatted, `analyze --fatal-infos` clean, tests written and green, acceptance
  criteria met, this checkbox ticked.
- **Deps:** a task may start only when every dependency listed is checked.

Legend: `[ ]` todo · `[x]` done & merged.

---

## M0 — Project setup & CI
- [x] **M0-T01** — Initialize the Flutter project: run `flutter create` to
  generate `android/`, `ios/`, etc.; verify Flutter ≥ 3.24 / Dart ≥ 3.5.
- [x] **M0-T02** — Apply `pubspec.yaml`; run `flutter pub get`; confirm
  `build_runner` runs clean. _Deps: M0-T01._
- [x] **M0-T03** — Apply `analysis_options.yaml`; fix any baseline lint;
  confirm `dart format` and `flutter analyze` pass. _Deps: M0-T02._
- [x] **M0-T04** — Create the `core/ data/ domain/ features/` folder structure
  with placeholder barrel files. _Deps: M0-T01._
- [x] **M0-T05** — App shell: `go_router` skeleton, Material 3 theme, a single
  placeholder route. _Deps: M0-T03, M0-T04._
- [ ] **M0-T06** — Verify `ci.yml` is green on a real pull request. _Deps: M0-T05._
- [ ] **M0-T07** — Verify `build.yml` produces an Android APK artifact. _Deps: M0-T06._
- [x] **M0-T08** — Project `README` + `CONTRIBUTING` pointing at `docs/`. _Deps: M0-T01._

## M1 — Data layer foundations
- [x] **M1-T01** — `Money` value object (`core/money/`). _Deps: M0-T05._
- [x] **M1-T02** — `MonthKey` value object (`core/time/`). _Deps: M0-T05._
- [x] **M1-T03** — Shared domain enums (account type, cleared status, flag
  color, schedule frequency, target type, system group type). _Deps: M0-T05._
- [x] **M1-T04** — `AppDatabase` skeleton: connection, `schemaVersion = 1`,
  testing constructor, Riverpod provider. _Deps: M1-T03._
- [x] **M1-T05** — Tables: `budgets`, `accounts`. _Deps: M1-T04._
- [x] **M1-T06** — Tables: `category_groups`, `categories`. _Deps: M1-T04._
- [x] **M1-T07** — Tables: `category_budgets`, `targets`. _Deps: M1-T06._
- [x] **M1-T08** — Tables: `payees`, `settings`. _Deps: M1-T04._
- [x] **M1-T09** — Tables: `transactions`, `sub_transactions`. _Deps: M1-T05, M1-T06._
- [x] **M1-T10** — Table: `scheduled_transactions`. _Deps: M1-T05, M1-T06._
- [x] **M1-T11** — Wire all tables into `AppDatabase`; `MigrationStrategy`
  skeleton; export schema JSON. _Deps: M1-T05..M1-T10._
- [x] **M1-T12** — `Account` entity + `AccountRepository` interface. _Deps: M1-T01._
- [x] **M1-T13** — `AccountsDao`. _Deps: M1-T11._
- [x] **M1-T14** — `AccountRepositoryImpl` + row↔entity mappers + tests. _Deps: M1-T12, M1-T13._
- [x] **M1-T15** — `CategoryGroup` + `Category` entities + `CategoryRepository`
  interface. _Deps: M1-T01._
- [x] **M1-T16** — `CategoriesDao`. _Deps: M1-T11._
- [x] **M1-T17** — `CategoryRepositoryImpl` + mappers + tests. _Deps: M1-T15, M1-T16._
- [x] **M1-T18** — `CategoryBudget` entity + repo interface + DAO + impl. _Deps: M1-T11, M1-T02._
- [x] **M1-T19** — `Transaction` + `SubTransaction` entities + `TransactionRepository`
  interface. _Deps: M1-T01._
- [x] **M1-T20** — `TransactionsDao` (incl. split & transfer queries). _Deps: M1-T11._
- [x] **M1-T21** — `TransactionRepositoryImpl` + mappers + tests. _Deps: M1-T19, M1-T20._
- [x] **M1-T22** — `Payee` entity + repo interface + DAO + impl. _Deps: M1-T11._
- [x] **M1-T23** — `Target` entity + repo interface + DAO + impl. _Deps: M1-T11._
- [x] **M1-T24** — `ScheduledTransaction` entity + repo interface + DAO + impl. _Deps: M1-T11._
- [x] **M1-T25** — `Budget` entity + repo + DAO + impl; `SettingsStore`. _Deps: M1-T11._
- [x] **M1-T26** — Riverpod providers exposing every repository (DI wiring). _Deps: M1-T14..M1-T25._

## M2 — Budget engine (pure `domain/budgeting/`)
- [x] **M2-T01** — `BudgetFixture` test helper: builds a known in-memory budget. _Deps: M1-T26._
- [x] **M2-T02** — Account balance calculator (working / cleared / uncleared). _Deps: M2-T01._
- [x] **M2-T03** — Category activity calculator (incl. splits). _Deps: M2-T01._
- [x] **M2-T04** — Category available calculator — simple rollover. _Deps: M2-T03._
- [x] **M2-T05** — Ready-to-Assign calculator. _Deps: M2-T03._
- [x] **M2-T06** — `MonthBudget` aggregate entity. _Deps: M2-T04, M2-T05._
- [x] **M2-T07** — `BudgetService.computeMonth` wiring repositories + engine. _Deps: M2-T06._
- [x] **M2-T08** — Operation: move money between categories. _Deps: M2-T07._
- [x] **M2-T09** — Operation: assign / set a category budget. _Deps: M2-T07._
- [x] **M2-T10** — Auto-create a credit-card payment category on CC account create. _Deps: M2-T01._
- [x] **M2-T11** — Transfer handling in balance calculation. _Deps: M2-T02._
- [x] **M2-T12** — Full overspending rule (cash vs credit rollover). _Deps: M2-T04, M2-T13._
- [x] **M2-T13** — Credit-card spend → payment-category movement. _Deps: M2-T10._
- [x] **M2-T14** — `advance(date, frequency)` scheduled-date function. _Deps: M2-T01._
- [ ] **M2-T15** — Target progress calculator (all four target types). _Deps: M2-T04._
- [ ] **M2-T16** — Engine invariant checks + property-style tests. _Deps: M2-T07..M2-T15._

## M3 — Accounts feature
- [ ] **M3-T01** — Account list controller. _Deps: M1-T26._
- [ ] **M3-T02** — Account list screen. _Deps: M3-T01._
- [ ] **M3-T03** — Account list item widget (name + balance). _Deps: M2-T02._
- [ ] **M3-T04** — Create-account form controller. _Deps: M1-T26._
- [ ] **M3-T05** — Create-account screen (type, name, starting balance). _Deps: M3-T04._
- [ ] **M3-T06** — Edit-account screen. _Deps: M3-T04._
- [ ] **M3-T07** — Close / reopen account action. _Deps: M3-T01._
- [ ] **M3-T08** — Delete account (guarded if it has transactions). _Deps: M3-T01._
- [ ] **M3-T09** — Account detail controller. _Deps: M2-T02._
- [ ] **M3-T10** — Account detail screen (balance header). _Deps: M3-T09._
- [ ] **M3-T11** — Sidebar account groups (Budget / Tracking / Closed). _Deps: M3-T02._
- [ ] **M3-T12** — Net-worth summary widget. _Deps: M2-T02._
- [ ] **M3-T13** — Account routes in `go_router`. _Deps: M3-T02, M3-T05, M3-T10._
- [ ] **M3-T14** — Widget tests for the account screens. _Deps: M3-T13._

## M4 — Transactions feature
- [ ] **M4-T01** — Transaction list controller (per account). _Deps: M1-T26._
- [ ] **M4-T02** — Transaction list screen. _Deps: M4-T01._
- [ ] **M4-T03** — Transaction row widget. _Deps: M4-T01._
- [ ] **M4-T04** — Add-transaction controller. _Deps: M1-T26._
- [ ] **M4-T05** — Add-transaction screen + amount keypad. _Deps: M4-T04._
- [ ] **M4-T06** — Date picker field. _Deps: M4-T05._
- [ ] **M4-T07** — Payee select / create field. _Deps: M4-T05._
- [ ] **M4-T08** — Category select field. _Deps: M4-T05._
- [ ] **M4-T09** — Cleared-status toggle. _Deps: M4-T05._
- [ ] **M4-T10** — Flag-color picker. _Deps: M4-T05._
- [ ] **M4-T11** — Save transaction. _Deps: M4-T06..M4-T10._
- [ ] **M4-T12** — Edit-transaction screen. _Deps: M4-T11._
- [ ] **M4-T13** — Delete transaction (soft delete). _Deps: M4-T01._
- [ ] **M4-T14** — Split-transaction editor controller. _Deps: M4-T04._
- [ ] **M4-T15** — Split-transaction editor UI. _Deps: M4-T14._
- [ ] **M4-T16** — Split validation (sub-amounts sum to total). _Deps: M4-T14._
- [ ] **M4-T17** — Transfer transaction: create the linked pair. _Deps: M4-T11._
- [ ] **M4-T18** — Transfer edit / delete keeps the pair consistent. _Deps: M4-T17._
- [ ] **M4-T19** — Scheduled-transaction create / edit. _Deps: M4-T11._
- [ ] **M4-T20** — Scheduled-transaction materialization service (runs at launch). _Deps: M2-T14, M4-T19._
- [ ] **M4-T21** — Upcoming-transactions view. _Deps: M4-T20._
- [ ] **M4-T22** — Transaction search & filter controller. _Deps: M4-T01._
- [ ] **M4-T23** — Transaction search UI. _Deps: M4-T22._
- [ ] **M4-T24** — Widget tests for transaction flows. _Deps: M4-T23._

## M5 — Budget view
- [ ] **M5-T01** — Budget screen controller (computes `MonthBudget`). _Deps: M2-T07._
- [ ] **M5-T02** — Budget screen scaffold + month header. _Deps: M5-T01._
- [ ] **M5-T03** — Month navigation (prev / next). _Deps: M5-T02._
- [ ] **M5-T04** — Ready-to-Assign header widget. _Deps: M5-T02._
- [ ] **M5-T05** — Collapsible category-group row widget. _Deps: M5-T02._
- [ ] **M5-T06** — Category row widget (assigned / activity / available). _Deps: M5-T05._
- [ ] **M5-T07** — Inline assigned-amount editor. _Deps: M2-T09, M5-T06._
- [ ] **M5-T08** — Move-money dialog. _Deps: M2-T08, M5-T06._
- [ ] **M5-T09** — Create category group. _Deps: M5-T05._
- [ ] **M5-T10** — Create category. _Deps: M5-T06._
- [ ] **M5-T11** — Rename category / group. _Deps: M5-T06._
- [ ] **M5-T12** — Reorder categories & groups (drag). _Deps: M5-T06._
- [ ] **M5-T13** — Hide / unhide category. _Deps: M5-T06._
- [ ] **M5-T14** — Delete category (guarded if it has activity). _Deps: M5-T06._
- [ ] **M5-T15** — Category inspector panel. _Deps: M5-T06._
- [ ] **M5-T16** — Available-pill colour logic. _Deps: M5-T06._
- [ ] **M5-T17** — Auto-assign helpers (to target / assigned-last-month). _Deps: M2-T15, M5-T07._
- [ ] **M5-T18** — Credit-card payment-group rendering. _Deps: M2-T13, M5-T05._
- [ ] **M5-T19** — Budget routes. _Deps: M5-T02._
- [ ] **M5-T20** — Widget tests for the budget screen. _Deps: M5-T19._

## M6 — Targets
- [ ] **M6-T01** — Target presentation model. _Deps: M1-T23._
- [ ] **M6-T02** — Create-target controller. _Deps: M6-T01._
- [ ] **M6-T03** — Target editor UI (type picker). _Deps: M6-T02._
- [ ] **M6-T04** — `monthlyFunding` editor. _Deps: M6-T03._
- [ ] **M6-T05** — `targetBalance` editor. _Deps: M6-T03._
- [ ] **M6-T06** — `targetBalanceByDate` editor (date picker). _Deps: M6-T03._
- [ ] **M6-T07** — Target-progress widget on the category row. _Deps: M2-T15, M5-T06._
- [ ] **M6-T08** — Underfunded badge + "needed" amount. _Deps: M6-T07._
- [ ] **M6-T09** — Edit / delete target. _Deps: M6-T03._
- [ ] **M6-T10** — Widget tests for targets. _Deps: M6-T08._

## M7 — Payees
- [ ] **M7-T01** — Payee list controller. _Deps: M1-T26._
- [ ] **M7-T02** — Payee management screen. _Deps: M7-T01._
- [ ] **M7-T03** — Rename / merge payee. _Deps: M7-T02._
- [ ] **M7-T04** — Delete payee. _Deps: M7-T02._
- [ ] **M7-T05** — Set a payee's default category. _Deps: M7-T02._
- [ ] **M7-T06** — Auto-categorize on transaction entry. _Deps: M7-T05, M4-T08._
- [ ] **M7-T07** — Payee routes. _Deps: M7-T02._
- [ ] **M7-T08** — Widget tests for payees. _Deps: M7-T07._

## M8 — CSV import
- [ ] **M8-T01** — File picker integration. _Deps: M1-T26._
- [ ] **M8-T02** — CSV parser (rows → raw records). _Deps: M8-T01._
- [ ] **M8-T03** — Column-mapping model. _Deps: M8-T02._
- [ ] **M8-T04** — Column-mapping UI. _Deps: M8-T03._
- [ ] **M8-T05** — Date / amount parsing for import. _Deps: M8-T03._
- [ ] **M8-T06** — Import dedup (`import_id`) logic. _Deps: M8-T05._
- [ ] **M8-T07** — Import-preview controller. _Deps: M8-T06._
- [ ] **M8-T08** — Import-review screen (approve / edit rows). _Deps: M8-T07._
- [ ] **M8-T09** — Commit import (write transactions). _Deps: M8-T08._
- [ ] **M8-T10** — Import error handling & report. _Deps: M8-T09._
- [ ] **M8-T11** — Tests for the import pipeline. _Deps: M8-T10._

## M9 — Reports
- [ ] **M9-T01** — Reports hub screen. _Deps: M1-T26._
- [ ] **M9-T02** — Date-range selector. _Deps: M9-T01._
- [ ] **M9-T03** — Spending-by-category aggregation. _Deps: M2-T03._
- [ ] **M9-T04** — Spending-by-category chart. _Deps: M9-T03._
- [ ] **M9-T05** — Spending-by-payee aggregation + view. _Deps: M2-T03._
- [ ] **M9-T06** — Income vs expense aggregation. _Deps: M2-T03._
- [ ] **M9-T07** — Income vs expense chart. _Deps: M9-T06._
- [ ] **M9-T08** — Net-worth aggregation over time. _Deps: M2-T02._
- [ ] **M9-T09** — Net-worth chart. _Deps: M9-T08._
- [ ] **M9-T10** — Age-of-Money calculator. _Deps: M2-T01._
- [ ] **M9-T11** — Age-of-Money display widget. _Deps: M9-T10._
- [ ] **M9-T12** — Tests for report aggregations. _Deps: M9-T09, M9-T11._

## M10 — Reconciliation & polish
- [ ] **M10-T01** — Reconciliation controller. _Deps: M2-T02._
- [ ] **M10-T02** — Reconcile flow UI (enter statement balance). _Deps: M10-T01._
- [ ] **M10-T03** — Create reconciliation adjustment transaction. _Deps: M10-T02._
- [ ] **M10-T04** — Lock reconciled transactions. _Deps: M10-T03._
- [ ] **M10-T05** — Settings screen. _Deps: M1-T25._
- [ ] **M10-T06** — Currency setting. _Deps: M10-T05._
- [ ] **M10-T07** — Date / number format setting. _Deps: M10-T05._
- [ ] **M10-T08** — Theme (light / dark) setting. _Deps: M10-T05._
- [ ] **M10-T09** — Backup: export the database to a file. _Deps: M1-T11._
- [ ] **M10-T10** — Restore: import a database file. _Deps: M10-T09._
- [ ] **M10-T11** — Onboarding flow controller. _Deps: M1-T26._
- [ ] **M10-T12** — Onboarding screens (welcome, first account, categories). _Deps: M10-T11._
- [ ] **M10-T13** — Seed starter categories / groups. _Deps: M10-T12._
- [ ] **M10-T14** — Empty states across all screens. _Deps: M3-T14, M4-T24, M5-T20._
- [ ] **M10-T15** — App-wide error handling & snackbars. _Deps: M10-T14._
- [ ] **M10-T16** — Integration test: a full budget cycle. _Deps: M10-T15._

## M11 — Release prep
- [ ] **M11-T01** — App icons (iOS + Android). _Deps: M10-T16._
- [ ] **M11-T02** — Splash screen. _Deps: M11-T01._
- [ ] **M11-T03** — App display name & bundle identifiers. _Deps: M10-T16._
- [ ] **M11-T04** — Android signing config. _Deps: M11-T03._
- [ ] **M11-T05** — iOS signing (Fastlane `match`). _Deps: M11-T03._
- [ ] **M11-T06** — Release CI: signed Android build + artifact upload. _Deps: M11-T04._
- [ ] **M11-T07** — Release CI: signed iOS build + TestFlight upload. _Deps: M11-T05._
- [ ] **M11-T08** — Store metadata & screenshots. _Deps: M11-T02._
- [ ] **M11-T09** — Versioning & release checklist. _Deps: M11-T06, M11-T07._

---

**Total: 174 tasks (M0–M11).** When a task is split, add the sub-IDs here and
keep the parent line for context.
