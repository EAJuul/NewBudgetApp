import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';

/// Ready to Assign = total inflow to RTA − total assigned.
///
/// Positive: money waiting for a job. Negative: over-assigned.
Money computeReadyToAssign({
  required Iterable<Account> accounts,
  required Iterable<Transaction> transactions,
  required Iterable<CategoryBudget> categoryBudgets,
}) {
  final onBudgetIds = {
    for (final a in accounts)
      if (a.onBudget) a.id,
  };

  var totalInflow = const Money.zero();
  for (final tx in transactions) {
    if (onBudgetIds.contains(tx.accountId) &&
        !tx.deleted &&
        !tx.isSplit &&
        tx.transferTransactionId == null &&
        tx.categoryId == null) {
      totalInflow = totalInflow + tx.amount;
    }
  }

  var totalAssigned = const Money.zero();
  for (final cb in categoryBudgets) {
    totalAssigned = totalAssigned + cb.assigned;
  }

  return totalInflow - totalAssigned;
}
