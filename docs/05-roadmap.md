# 05 — Roadmap & Milestones

Milestones are sequential; each has an **exit criterion** that must be green
(CI passing, tests written) before the next begins. Task counts are estimates —
the authoritative list is `06-task-breakdown.md`.

| ID | Milestone | Goal | ~Tasks |
|---|---|---|---|
| M0 | Project setup & CI | Compiling app, lints, green CI, smoke test | 8 |
| M1 | Data layer foundations | Drift DB, all tables, DAOs, repository interfaces + impls | 26 |
| M2 | Budget engine | Pure budgeting logic: RTA, available/rollover, credit cards, target math | 16 |
| M3 | Accounts feature | List/create/edit/close accounts; balances; account detail | 14 |
| M4 | Transactions feature | Add/edit/delete; splits; transfers; scheduled; cleared; search | 24 |
| M5 | Budget view | Monthly budget screen; categories CRUD; assign & move money; month nav | 20 |
| M6 | Targets | Target CRUD per category; progress badges; underfunded display | 10 |
| M7 | Payees | Payee management; default category; auto-categorize on entry | 8 |
| M8 | CSV import | File pick; parse; column mapping; dedup; import-review screen | 11 |
| M9 | Reports | Spending; income vs expense; net worth; Age of Money | 12 |
| M10 | Reconciliation & polish | Reconcile flow; settings; backup/restore; onboarding; empty states | 16 |
| M11 | Release prep | Icons; splash; store metadata; signing; release CI; beta builds | 9 |

**MVP = M0 through M11.** Rough total ≈ 174 tasks.

## Exit criteria
- **M0:** `flutter analyze` clean; `flutter test` green; CI workflow passing on a
  pull request.
- **M1:** every table has a DAO; every repository interface has an
  implementation plus a test that runs against an in-memory database.
- **M2:** the budget engine computes RTA, category available with rollover, and
  credit-card movement correctly against a hand-built fixture budget; ≥ 90% line
  coverage on `domain/budgeting/`.
- **M3–M10:** each feature's golden path and key edge cases pass widget tests,
  and the feature is reachable in the running app.
- **M11:** signed builds install and launch on a physical iOS and Android
  device.

## Milestone dependency graph
```
M0 → M1 → M2 → M3 → M4 → M5 → M6
                      M5 → M7
                M2,M4 → M8
          M2,M4,M5 → M9
     M3,M4,M5 → M10 → M11
```
M2 has no UI and can be built in parallel with M3 by a second agent once M1 is
complete.

## Critical path & risk
- **Highest-risk work:** the budget engine (M2), the credit-card logic
  (M2-T13), and wiring the budget screen (M5). These get the most tests and the
  smallest task slices.
- **Recommended order for a single agent:** strictly M0 → M11. The budget engine
  (M2) is pure and fully testable before any UI exists — do not skip it or fold
  it into M5.

## Post-MVP (not scheduled)
Cloud sync, automatic bank linking, multiple budgets, web/desktop builds,
scheduled splits, shared budgets. The data model and the repository abstraction
already accommodate the first three.
