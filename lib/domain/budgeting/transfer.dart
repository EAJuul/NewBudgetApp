import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';

/// The net milliunit amount transfers moved into [accountId]: the sum of the
/// signed `amount`s of that account's non-deleted transfer rows. Positive means
/// transfers brought money in; negative means they took money out.
Money netTransferAmount({
  required String accountId,
  required Iterable<Transaction> transactions,
}) {
  var total = const Money.zero();
  for (final tx in transactions) {
    if (tx.accountId == accountId && !tx.deleted && tx.isTransfer) {
      total = total + tx.amount;
    }
  }
  return total;
}
