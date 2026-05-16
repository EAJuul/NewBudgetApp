# 04 — Budgeting Logic (the domain engine)

This is the hardest part of the app and the most heavily tested. All logic here
is **pure Dart** in `lib/domain/budgeting/`, with no Flutter and no Drift
imports. Every function below maps to a task in milestone **M2**.

All amounts are integer milliunits (see `03-data-model.md`).

## Core derived quantities

### Account balances
For an account:
- **Working balance** = `SUM(amount)` over its non-deleted transactions.
- **Cleared balance** = the same, restricted to `cleared IN ('cleared','reconciled')`.
- **Uncleared balance** = working − cleared.

### Category Activity
`activity(category, month)` = the sum of transaction `amount`s assigned to that
category with `date` inside `month`, **plus** the amounts of sub-transactions
(splits) assigned to it. Activity is normally negative (spending).

### Category Available (with rollover)
Categories are processed month by month in chronological order:
```
available(cat, month) =
      carryover(cat, previousMonth)
    + assigned(cat, month)            // from category_budgets
    + activity(cat, month)            // usually negative
```
`carryover` is the previous month's `available` adjusted by the overspending
rule:
- `available(cat, prev) >= 0` → `carryover = available(cat, prev)`.
- `available(cat, prev) < 0` from **cash** overspending → `carryover = 0`
  (the negative is absorbed by Ready to Assign in `prev`, not pushed forward).
- `available(cat, prev) < 0` from **credit** overspending → `carryover =
  available(cat, prev)` (the negative rolls forward in the category).

> **MVP simplification (allowed).** The cash-vs-credit distinction may be
> deferred. A correct simpler first pass: all negative `available` rolls forward
> (`carryover = available(cat, prev)` always). Implement the full rule in task
> M2-T12 once the credit-card path exists. Tests must cover both modes.

### Ready to Assign (RTA)
A single global number:
```
RTA = totalInflowToRTA  −  totalAssigned
```
- `totalInflowToRTA` = the sum of all transaction amounts whose category is the
  special "Inflow: Ready to Assign" bucket, across all on-budget accounts, all
  dates. An on-budget account's starting-balance transaction is an inflow to RTA.
- `totalAssigned` = the sum of `assigned` across **all** `category_budgets` rows
  (every category, every month).

`RTA > 0`: money waiting for a job. `RTA < 0`: the user assigned more than they
have and must fix it.

## Credit cards (the special case)
A credit-card account has a paired **Credit Card Payment category** (in the
`creditCardPayments` group, linked through `categories.linked_account_id`).

When the user records an **outflow on a credit-card account** categorized to a
normal spending category `C`:
- It reduces `activity(C)` as usual — the user spent from that budget category.
- It simultaneously **moves budgeted money into the card's payment category**:
  the payment category's `available` increases by the spent amount, *capped at
  the amount that was available in `C` before the spend*. The engine adds a
  positive contribution to the payment category equal to
  `min(spend, availableInC_beforeSpend)`.
- Any remainder (spend beyond what `C` held) is **credit overspending** on `C`.

Paying the card is a **transfer** from a checking account to the credit-card
account; the checking side's category is the card's payment category (drawing
that set-aside money down). Interest is an outflow on the card categorized
directly to the payment category (increasing what is owed).

This is intricate — task **M2-T13** implements it with an exhaustive test
matrix: purchase fully funded, partially funded, unfunded; refund; payment;
interest charge.

## Age of Money (AoM)
A trailing metric, implemented in M9:
1. Build a FIFO queue of **income lots**: each inflow-to-RTA is a lot
   `(date, remainingAmount)`, oldest first.
2. Walk **outflows** oldest-first; each outflow consumes from the front of the
   queue. For each consumed portion record `ageDays = outflow.date − lot.date`,
   weighted by the amount consumed.
3. AoM = the amount-weighted average `ageDays` of the **most recent 10 outflow
   transactions**.

With fewer than 10 outflows, AoM is undefined — the UI shows "—".

## Scheduled transactions
A `scheduled_transaction` has a `frequency` and a `next_date`.
- **Materialization:** on app launch (and after a schedule is edited), for every
  schedule with `next_date <= today`, create a real `transaction`, then advance
  `next_date` by the frequency; repeat until `next_date > today`.
- **Upcoming view:** schedules with `next_date` within the next N days are shown
  as upcoming but not yet materialized.
- `advance(date, frequency)` is a pure function with its own tests; calendar
  edge cases (Jan 31 + monthly → Feb 28/29) must be covered.

## Target progress
For a category that has a target, for the viewed month:
- **monthlyFunding(T):** `needed = max(0, T − assigned(cat, month))`; status
  `funded` when `assigned >= T`.
- **monthlySpending(T):** like monthlyFunding but compares against `available`
  so prior rollover counts toward the target.
- **targetBalance(T):** `needed = max(0, T − available(cat, month))`; goal met
  when `available >= T`.
- **targetBalanceByDate(T, D):** `monthsLeft = monthsBetween(month, D)` (≥ 1);
  `needed = max(0, ceilDiv(T − available(cat, month), monthsLeft))`.

`needed` drives the "underfunded" badge on the budget screen (M6).

## Invariants the engine must never violate (assert + test)
1. With no credit overspending present, the sum of every category's `available`
   plus `RTA` equals the total working balance of all on-budget accounts.
2. A split transaction's `amount` equals the sum of its sub-transactions'
   `amount`s.
3. A transfer's two transaction rows hold equal and opposite `amount`s.
4. `assigned` may be negative — the user can pull money back out of a category
   into RTA.
5. No money calculation uses `double`.
