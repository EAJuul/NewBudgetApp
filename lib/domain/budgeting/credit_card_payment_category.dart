import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:budget_app/features/categories/domain/category.dart';

/// Builds the payment [Category] for the credit-card [account].
///
/// The category is linked back to the account via `linkedAccountId` and lives
/// in the `creditCardPayments` system group identified by [paymentGroupId].
/// [categoryId] is a caller-generated UUID. Throws [ArgumentError] when
/// [account] is not a credit-card account.
Category creditCardPaymentCategory({
  required Account account,
  required String paymentGroupId,
  required String categoryId,
  required int sortOrder,
}) {
  if (!account.type.isCreditCard) {
    throw ArgumentError.value(
      account.type,
      'account.type',
      'Only credit-card accounts get a payment category',
    );
  }
  return Category(
    id: categoryId,
    groupId: paymentGroupId,
    name: account.name,
    hidden: false,
    sortOrder: sortOrder,
    linkedAccountId: account.id,
  );
}
