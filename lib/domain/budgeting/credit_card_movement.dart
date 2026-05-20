import 'package:budget_app/core/money/money.dart';

/// The signed amount to add to a credit-card account's **payment category**
/// `available` for one transaction recorded on that card and categorised to a
/// normal spending category.
///
/// [transactionAmount] is signed (purchase negative, refund positive).
/// [categoryAvailableBeforeTransaction] is the spending category's `available`
/// immediately before this transaction is applied.
Money creditCardPaymentMovement({
  required Money transactionAmount,
  required Money categoryAvailableBeforeTransaction,
}) {
  if (transactionAmount.isZero) return const Money.zero();

  if (transactionAmount.isNegative) {
    // Purchase: move the funded portion into the payment category.
    final spend = transactionAmount.abs();
    final funded = categoryAvailableBeforeTransaction > const Money.zero()
        ? categoryAvailableBeforeTransaction
        : const Money.zero();
    final moved = spend < funded ? spend : funded;
    return moved;
  }

  // Refund: reverse the full amount out of the payment category.
  // NEEDS REVIEW: docs/04 does not specify the refund cap precisely.
  // Implemented as full reversal (−transactionAmount) pending confirmation.
  return -transactionAmount;
}

/// The portion of a credit-card purchase that the spending category could NOT
/// cover — i.e. credit overspending. Always >= 0. Consumed by M2-T12.
Money creditOverspendingPortion({
  required Money transactionAmount,
  required Money categoryAvailableBeforeTransaction,
}) {
  if (!transactionAmount.isNegative) return const Money.zero();

  final spend = transactionAmount.abs();
  final funded = categoryAvailableBeforeTransaction > const Money.zero()
      ? categoryAvailableBeforeTransaction
      : const Money.zero();
  final moved = spend < funded ? spend : funded;
  return spend - moved;
}
