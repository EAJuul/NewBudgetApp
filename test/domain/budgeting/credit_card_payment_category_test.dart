import 'package:budget_app/domain/budgeting/credit_card_payment_category.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const creditCardAccount = Account(
    id: 'acc-1',
    budgetId: 'budget-1',
    name: 'Visa',
    type: AccountType.creditCard,
    onBudget: true,
    closed: false,
    sortOrder: 0,
  );

  group('creditCardPaymentCategory', () {
    test('builds correctly linked Category for a credit-card account', () {
      final category = creditCardPaymentCategory(
        account: creditCardAccount,
        paymentGroupId: 'grp-cc',
        categoryId: 'cat-1',
        sortOrder: 3,
      );

      expect(category.linkedAccountId, creditCardAccount.id);
      expect(category.name, creditCardAccount.name);
      expect(category.groupId, 'grp-cc');
      expect(category.isCreditCardPayment, isTrue);
    });

    test('uses the supplied categoryId and sortOrder', () {
      final category = creditCardPaymentCategory(
        account: creditCardAccount,
        paymentGroupId: 'grp-cc',
        categoryId: 'my-uuid',
        sortOrder: 7,
      );

      expect(category.id, 'my-uuid');
      expect(category.sortOrder, 7);
    });

    test('throws ArgumentError for a checking account', () {
      const checking = Account(
        id: 'acc-2',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 0,
      );

      expect(
        () => creditCardPaymentCategory(
          account: checking,
          paymentGroupId: 'grp-cc',
          categoryId: 'cat-2',
          sortOrder: 0,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for an asset account', () {
      const asset = Account(
        id: 'acc-3',
        budgetId: 'budget-1',
        name: 'House',
        type: AccountType.asset,
        onBudget: false,
        closed: false,
        sortOrder: 0,
      );

      expect(
        () => creditCardPaymentCategory(
          account: asset,
          paymentGroupId: 'grp-cc',
          categoryId: 'cat-3',
          sortOrder: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
