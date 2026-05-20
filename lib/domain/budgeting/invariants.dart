import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/budgeting/month_budget.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';

/// Invariant 1: sum of every category's `available` plus readyToAssign
/// equals the total working balance of all on-budget accounts.
/// Precondition: no credit overspending in the budget.
/// Returns null when it holds, else a human-readable message.
String? checkBudgetEquation({
  required MonthBudget monthBudget,
  required Money onBudgetWorkingTotal,
}) {
  var categorySum = const Money.zero();
  for (final line in monthBudget.lines) {
    categorySum = categorySum + line.available;
  }

  final expectedTotal = categorySum + monthBudget.readyToAssign;

  if (expectedTotal == onBudgetWorkingTotal) {
    return null;
  }

  return 'Budget equation failed: sum(available)=${categorySum.milliunits} + '
      'readyToAssign=${monthBudget.readyToAssign.milliunits} != '
      'onBudgetWorkingTotal=${onBudgetWorkingTotal.milliunits}';
}

/// Invariant 2: a split transaction's `amount` equals the sum of its
/// non-deleted sub-transactions' `amount`s. Returns null when it holds.
String? checkSplitSum({
  required Transaction parent,
  required Iterable<SubTransaction> subTransactions,
}) {
  if (!parent.isSplit) {
    return null;
  }

  var subSum = const Money.zero();
  for (final sub in subTransactions) {
    if (!sub.deleted) {
      subSum = subSum + sub.amount;
    }
  }

  if (subSum == parent.amount) {
    return null;
  }

  return 'Split sum failed: parent(id=${parent.id}, amount=${parent.amount.milliunits}) '
      'sum(subTransactions)=${subSum.milliunits}';
}

/// Invariant 3: two rows of a transfer hold equal and opposite amounts
/// and cross-reference each other's ids. Returns null when it holds.
String? checkTransferPair(Transaction a, Transaction b) {
  final isAmountCorrect = a.amount == -b.amount;
  final isAtoB = a.transferTransactionId == b.id;
  final isBtoA = b.transferTransactionId == a.id;

  if (isAmountCorrect && isAtoB && isBtoA) {
    return null;
  }

  return 'Transfer pair failed: '
      'a(id=${a.id}, amount=${a.amount.milliunits}, transferId=${a.transferTransactionId}) '
      'b(id=${b.id}, amount=${b.amount.milliunits}, transferId=${b.transferTransactionId}). '
      'Expected: amounts opposite, cross-referenced ids.';
}
