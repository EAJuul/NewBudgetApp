import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Account', () {
    test('Construct with all fields and verify each field', () {
      const account = Account(
        id: 'account-1',
        budgetId: 'budget-1',
        name: 'Checking Account',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
        note: 'Primary checking account',
      );

      expect(account.id, 'account-1');
      expect(account.budgetId, 'budget-1');
      expect(account.name, 'Checking Account');
      expect(account.type, AccountType.checking);
      expect(account.onBudget, true);
      expect(account.closed, false);
      expect(account.note, 'Primary checking account');
      expect(account.sortOrder, 1);
    });

    test('copyWith returns new instance with updated name', () {
      const original = Account(
        id: 'account-1',
        budgetId: 'budget-1',
        name: 'Old Name',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
      );

      final updated = original.copyWith(name: 'New Name');

      expect(updated.name, 'New Name');
      expect(original.name, 'Old Name');
      expect(updated.id, original.id);
      expect(updated.budgetId, original.budgetId);
      expect(updated.type, original.type);
    });

    test('Two instances with identical args are equal and have same hashCode',
        () {
      const account1 = Account(
        id: 'account-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
        note: 'Note',
      );

      const account2 = Account(
        id: 'account-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
        note: 'Note',
      );

      expect(account1, account2);
      expect(account1.hashCode, account2.hashCode);
    });

    test('Two instances differing only in id are not equal', () {
      const account1 = Account(
        id: 'account-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
        note: 'Note',
      );

      const account2 = Account(
        id: 'account-2',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
        note: 'Note',
      );

      expect(account1, isNot(account2));
    });

    test('AccountType.isOnBudget is true for checking and savings', () {
      expect(AccountType.checking.isOnBudget, true);
      expect(AccountType.savings.isOnBudget, true);
    });

    test('AccountType.isOnBudget is false for asset and liability', () {
      expect(AccountType.asset.isOnBudget, false);
      expect(AccountType.liability.isOnBudget, false);
    });
  });
}
