import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';

/// Activity for [categoryId] within [month]. Normally negative (spending).
///
/// Sub-transactions are dated by their parent transaction's `date`.
Money computeCategoryActivity({
  required String categoryId,
  required MonthKey month,
  required Iterable<Transaction> transactions,
  required Iterable<SubTransaction> subTransactions,
}) {
  // Index transactions by id for O(1) parent lookup
  final txMap = {for (final tx in transactions) tx.id: tx};

  var total = Money.zero();

  // Direct (non-split) contributions
  for (final tx in transactions) {
    if (tx.categoryId == categoryId &&
        !tx.isSplit &&
        !tx.deleted &&
        month.contains(tx.date)) {
      total = total + tx.amount;
    }
  }

  // Split sub-transaction contributions
  for (final sub in subTransactions) {
    if (sub.categoryId == categoryId && !sub.deleted) {
      final parent = txMap[sub.transactionId];
      if (parent != null && !parent.deleted && month.contains(parent.date)) {
        total = total + sub.amount;
      }
    }
  }

  return total;
}
