# 01 — Vision & Scope

## Product vision
NewBudgetApp is a cross-platform (iOS + Android) personal budgeting app built on
the YNAB ("You Need A Budget") methodology of **zero-based, forward-allocated
budgeting**: every unit of money the user holds is given a job before it is
spent.

The MVP is **local-first** — all data lives on the device in an SQLite database,
with no account, no server, and no network dependency. This keeps the first
release shippable, private, and free to operate. The architecture (see
`02-architecture.md`) isolates persistence behind repository interfaces so a
sync backend can be added later without touching feature code.

## The method (why the app is shaped this way)
YNAB is built on four rules. The app must make each one natural:

1. **Give every dollar a job** — income flows into "Ready to Assign"; the user
   assigns it to categories until Ready to Assign reaches 0.
2. **Embrace your true expenses** — large/irregular expenses are broken into
   smaller monthly target amounts.
3. **Roll with the punches** — when a category is overspent, the user moves
   money between categories; nothing is locked.
4. **Age your money** — the app surfaces an "Age of Money" metric to encourage
   spending money that is at least 30 days old.

## Feature parity matrix
Legend: ✅ in MVP · 🔜 post-MVP · ❌ out of scope

| Area | Feature | Status |
|---|---|---|
| Budgeting | Monthly budget view (Assigned / Activity / Available) | ✅ |
| Budgeting | Ready to Assign | ✅ |
| Budgeting | Category groups & categories; reorder; hide | ✅ |
| Budgeting | Available rollover between months | ✅ |
| Budgeting | Move money between categories | ✅ |
| Budgeting | Overspending handling (cash vs credit) | ✅ |
| Accounts | Budget accounts: checking, savings, cash, credit card, line of credit | ✅ |
| Accounts | Tracking accounts: asset / liability | ✅ |
| Accounts | Reconciliation | ✅ |
| Accounts | Credit-card payment categories & payoff logic | ✅ |
| Transactions | Add/edit/delete; inflow/outflow; cleared status; flags | ✅ |
| Transactions | Split transactions | ✅ |
| Transactions | Transfers between accounts | ✅ |
| Transactions | Scheduled / recurring transactions | ✅ |
| Transactions | Search & filter | ✅ |
| Payees | Payee list; default category; auto-categorization | ✅ |
| Targets | Monthly funding; target balance; target balance by date | ✅ |
| Reports | Spending by category/payee; income vs expense; net worth | ✅ |
| Reports | Age of Money | ✅ |
| Import | CSV / file import with column mapping & dedup | ✅ |
| Data | Local backup & restore (export/import a file) | ✅ |
| Settings | Currency; date & number format | ✅ |
| Onboarding | First-run setup (create accounts, starter categories) | ✅ |
| Sync | Multi-device cloud sync | 🔜 |
| Import | Automatic bank linking (Plaid / GoCardless) | 🔜 |
| Budgeting | Multiple budgets per user | 🔜 |
| Platform | Web / desktop build | 🔜 |
| Misc | Shared / multi-user budgets | ❌ |

## Non-goals for the MVP
- No server, no authentication, no cloud account.
- No real-money movement — the app never initiates a transfer at a bank.
- Single budget per install (the data model supports more; the UI does not yet).
- Single currency per budget (no live FX conversion).

## Definition of "MVP done"
Every ✅ row above is implemented, each behind passing unit/widget tests, with
CI green and a signed build installable on a physical iOS and Android device.
See `05-roadmap.md` for the milestone path.

## Target users
People who already practice envelope / zero-based budgeting (current YNAB users
are the reference persona) and want a private, offline, one-time-cost
alternative.
