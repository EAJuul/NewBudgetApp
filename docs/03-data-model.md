# 03 — Data Model

## Money representation — read this first
All monetary amounts are stored and computed as **integer milliunits**:
`1 currency unit = 1000 milliunits`. `$12.34` → `12340`. This matches YNAB's own
API convention and makes every calculation exact.

- **Never use `double` for money. No exceptions.**
- Outflows are **negative**, inflows **positive**. A transaction `amount` is
  signed.
- Conversion to/from display strings happens only in
  `core/money/CurrencyFormatter`.
- The `Money` value object (`core/money/money.dart`, task M1-T01) wraps the int
  and exposes `+`, `-`, comparison, and formatting. Domain code passes `Money`;
  database columns store its raw `int`.

## Dates
- A **month** is identified by a `MonthKey` value object (year + month),
  persisted as text `YYYY-MM` (e.g. `2026-05`). Budget data is keyed by month.
- Transaction dates are stored as text `YYYY-MM-DD`. SQLite has no date type;
  ISO-8601 text sorts correctly and is unambiguous.
- Timestamps (`created_at`, `updated_at`) are text `YYYY-MM-DDTHH:MM:SSZ` (UTC).

## Storage engine
A single SQLite database via **Drift**. One `AppDatabase` class; table
definitions in `lib/data/database/tables/`; query logic in DAOs
(`lib/data/daos/`). Drift provides type-safe queries, reactive `Stream`s, and
schema migrations.

## Entity–relationship overview
```
Budget 1──* Account 1──* Transaction *──1 Payee
                              │ 1
                              └──* SubTransaction (splits)
Budget 1──* CategoryGroup 1──* Category 1──* CategoryBudget (per month: assigned)
                                   │ 1
                                   └──0..1 Target
Account (credit card) 1──1 Category (its "Credit Card Payment" category)
Transaction 0..1──0..1 Transaction (transfer: a linked pair)
ScheduledTransaction *──1 Account, *──0..1 Category, *──0..1 Payee
```

## Conventions for every table
- Primary key `id` is `TEXT` holding a **UUID v4 generated in Dart** (never by
  the DB) so rows are stable across a future sync.
- `created_at` / `updated_at` text timestamps on all mutable tables.
- Deletes are **soft** (`deleted` boolean) on `transactions` and
  `sub_transactions` to preserve history; other tables hard-delete.
- Booleans are stored as SQLite `INTEGER` 0/1 (Drift maps them to `bool`).

## Tables

### budgets
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| name | TEXT | |
| currency_code | TEXT | ISO 4217, e.g. `USD` |
| currency_decimal_digits | INT | display only; storage is always milliunits |
| date_format | TEXT | e.g. `MM/dd/yyyy` |
| created_at / updated_at | TEXT | |

MVP creates exactly one row. Kept as a table for the post-MVP multi-budget
feature.

### accounts
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| budget_id | TEXT FK→budgets | |
| name | TEXT | |
| type | TEXT | enum: `checking`,`savings`,`cash`,`creditCard`,`lineOfCredit`,`asset`,`liability` |
| on_budget | INT(bool) | true for the first five types; false for `asset`/`liability` |
| closed | INT(bool) | |
| note | TEXT? | |
| sort_order | INT | |
| created_at / updated_at | TEXT | |

Account balances are **not stored** — they are `SUM(transactions.amount)`. See
`04-budgeting-logic.md`.

### category_groups
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| budget_id | TEXT FK | |
| name | TEXT | |
| hidden | INT(bool) | |
| sort_order | INT | |
| system_type | TEXT? | null for normal groups; `creditCardPayments` or `internal` for system groups |

### categories
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| group_id | TEXT FK→category_groups | |
| name | TEXT | |
| hidden | INT(bool) | |
| note | TEXT? | |
| sort_order | INT | |
| linked_account_id | TEXT? FK→accounts | set only for a credit-card payment category |
| created_at / updated_at | TEXT | |

The special **"Ready to Assign"** bucket is not a category row; it is a computed
value (see `04`). Each credit-card account auto-creates one category in the
`creditCardPayments` group.

### category_budgets
The per-month assignment. One row per (category, month) ever touched.
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| category_id | TEXT FK→categories | |
| month | TEXT | `YYYY-MM` |
| assigned | INT | milliunits assigned to this category this month (may be negative) |
| created_at / updated_at | TEXT | |
| UNIQUE(category_id, month) | | |

`activity` and `available` are **derived**, never stored — see `04`.

### payees
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| budget_id | TEXT FK | |
| name | TEXT | |
| default_category_id | TEXT? FK→categories | drives auto-categorization |
| transfer_account_id | TEXT? FK→accounts | set if the payee represents "Transfer: <account>" |

### transactions
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| account_id | TEXT FK→accounts | |
| date | TEXT | `YYYY-MM-DD` |
| amount | INT | signed milliunits; equals the sum of sub-rows when `is_split` |
| payee_id | TEXT? FK→payees | |
| category_id | TEXT? FK→categories | null when split, transfer between budget accounts, or inflow-to-RTA |
| memo | TEXT? | |
| cleared | TEXT | enum: `uncleared`,`cleared`,`reconciled` |
| approved | INT(bool) | false for unreviewed imported rows |
| flag_color | TEXT? | enum: `red`,`orange`,`yellow`,`green`,`blue`,`purple` |
| transfer_transaction_id | TEXT? FK→transactions | the paired side of a transfer |
| transfer_account_id | TEXT? FK→accounts | the other account in a transfer |
| scheduled_transaction_id | TEXT? FK | the schedule that generated this row |
| import_id | TEXT? | dedup key for CSV import |
| is_split | INT(bool) | true → categories live in `sub_transactions` |
| deleted | INT(bool) | soft delete |
| created_at / updated_at | TEXT | |

### sub_transactions (splits)
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| transaction_id | TEXT FK→transactions | |
| amount | INT | signed milliunits; the sum across a parent equals `parent.amount` |
| category_id | TEXT? FK→categories | |
| payee_id | TEXT? FK→payees | |
| memo | TEXT? | |
| deleted | INT(bool) | |

### scheduled_transactions
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| account_id | TEXT FK | |
| amount | INT | |
| payee_id / category_id | TEXT? FK | |
| memo | TEXT? | |
| frequency | TEXT | enum: `daily`,`weekly`,`everyOtherWeek`,`twiceAMonth`,`every4Weeks`,`monthly`,`everyOtherMonth`,`every3Months`,`every6Months`,`yearly` |
| next_date | TEXT | `YYYY-MM-DD` — next occurrence to materialize |
| created_at / updated_at | TEXT | |

MVP scheduled transactions are single-category; scheduled splits are post-MVP.

### targets
0..1 per category.
| column | type | notes |
|---|---|---|
| id | TEXT PK | |
| category_id | TEXT FK→categories UNIQUE | |
| type | TEXT | enum: `monthlyFunding`,`targetBalance`,`targetBalanceByDate`,`monthlySpending` |
| amount | INT | milliunits |
| target_month | TEXT? | `YYYY-MM`, used by `targetBalanceByDate` |
| created_at / updated_at | TEXT | |

### settings
Key–value table for app preferences not tied to a budget (theme, last-opened
month, onboarding-complete flag). Columns: `key TEXT PK`, `value TEXT`.

## Migrations
The Drift `schemaVersion` starts at **1**. Every schema change increments it and
adds a step to the `MigrationStrategy`. The schema is also exported as JSON to
`drift_schema/` so migration tests can verify upgrades step by step. See
`07-testing-strategy.md`.

## Seed data (first run)
On first launch the onboarding flow (M10) creates: one `budget`; the system
category groups (`Credit Card Payments`, `Hidden Categories`); and a starter set
of groups/categories mirroring YNAB's defaults (Immediate Obligations, True
Expenses, Quality of Life, Just for Fun).
