import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/data/account_mappers.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('accountFromRow', () {
    test('maps all fields correctly including note', () {
      const row = AccountRow(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        note: 'Main account',
        sortOrder: 1,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
      );

      final account = accountFromRow(row);

      expect(account.id, 'acc-1');
      expect(account.budgetId, 'budget-1');
      expect(account.name, 'Checking');
      expect(account.type, AccountType.checking);
      expect(account.onBudget, isTrue);
      expect(account.closed, isFalse);
      expect(account.note, 'Main account');
      expect(account.sortOrder, 1);
    });

    test('maps AccountRow with null note correctly', () {
      const row = AccountRow(
        id: 'acc-2',
        budgetId: 'budget-1',
        name: 'Savings',
        type: AccountType.savings,
        onBudget: true,
        closed: false,
        sortOrder: 2,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
      );

      final account = accountFromRow(row);

      expect(account.note, isNull);
    });
  });

  group('accountToCompanion', () {
    test('produces companion with Value-wrapped fields and supplied timestamps',
        () {
      const account = Account(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        note: 'Main account',
        sortOrder: 1,
      );

      const createdAt = '2026-01-01T00:00:00Z';
      const updatedAt = '2026-01-02T00:00:00Z';
      final companion = accountToCompanion(
        account,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(companion.id.value, 'acc-1');
      expect(companion.budgetId.value, 'budget-1');
      expect(companion.name.value, 'Checking');
      expect(companion.type.value, AccountType.checking);
      expect(companion.onBudget.value, isTrue);
      expect(companion.closed.value, isFalse);
      expect(companion.note.value, 'Main account');
      expect(companion.sortOrder.value, 1);
      expect(companion.createdAt.value, createdAt);
      expect(companion.updatedAt.value, updatedAt);
    });
  });

  group('round-trip mapping', () {
    test('nullable note field round-trips as null', () {
      const row = AccountRow(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Savings',
        type: AccountType.savings,
        onBudget: true,
        closed: false,
        sortOrder: 1,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
      );

      final account = accountFromRow(row);
      final companion = accountToCompanion(
        account,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

      expect(companion.note.value, isNull);
    });

    test('nullable note field round-trips with value', () {
      const row = AccountRow(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        note: 'Important account',
        sortOrder: 1,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
      );

      final account = accountFromRow(row);
      final companion = accountToCompanion(
        account,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

      expect(companion.note.value, 'Important account');
    });
  });
}
