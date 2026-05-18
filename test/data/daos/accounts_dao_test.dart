import 'package:budget_app/data/daos/accounts_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountsDao', () {
    late AppDatabase db;
    late AccountsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = AccountsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('upsert a new account, then findById returns row with matching fields',
        () async {
      // Insert parent budget
      const budgetId = 'budget-1';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Test Budget',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'MM/dd/yyyy',
              createdAt: '2026-05-18T00:00:00Z',
              updatedAt: '2026-05-18T00:00:00Z',
            ),
          );

      // Upsert a new account
      const accountId = 'account-1';
      const accountName = 'Checking';
      await dao.upsert(
        AccountsCompanion.insert(
          id: accountId,
          budgetId: budgetId,
          name: accountName,
          type: AccountType.checking,
          onBudget: true,
          closed: false,
          sortOrder: 1,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:00:00Z',
        ),
      );

      // Find by ID and verify
      final account = await dao.findById(accountId);
      expect(account, isNotNull);
      expect(account!.id, accountId);
      expect(account.budgetId, budgetId);
      expect(account.name, accountName);
      expect(account.type, AccountType.checking);
      expect(account.onBudget, true);
      expect(account.closed, false);
      expect(account.sortOrder, 1);
    });

    test(
        'upsert account with same id but changed name; findById shows updated name; only one row exists',
        () async {
      // Insert parent budget
      const budgetId = 'budget-2';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Test Budget 2',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'MM/dd/yyyy',
              createdAt: '2026-05-18T00:00:00Z',
              updatedAt: '2026-05-18T00:00:00Z',
            ),
          );

      // Upsert first account
      const accountId = 'account-2';
      await dao.upsert(
        AccountsCompanion.insert(
          id: accountId,
          budgetId: budgetId,
          name: 'Checking',
          type: AccountType.checking,
          onBudget: true,
          closed: false,
          sortOrder: 1,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:00:00Z',
        ),
      );

      // Upsert same account with different name
      await dao.upsert(
        AccountsCompanion.insert(
          id: accountId,
          budgetId: budgetId,
          name: 'Updated Checking',
          type: AccountType.checking,
          onBudget: true,
          closed: false,
          sortOrder: 1,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:01:00Z',
        ),
      );

      // Verify updated name
      final account = await dao.findById(accountId);
      expect(account, isNotNull);
      expect(account!.name, 'Updated Checking');

      // Verify only one row exists
      final allAccounts = await (db.select(db.accounts)
            ..where((t) => t.budgetId.equals(budgetId)))
          .get();
      expect(allAccounts.length, 1);
    });

    test(
        'watchByBudget emits accounts for that budget ordered by sortOrder, excludes other budget accounts',
        () async {
      // Insert two budgets
      const budgetId1 = 'budget-3';
      const budgetId2 = 'budget-4';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId1,
              name: 'Budget 1',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'MM/dd/yyyy',
              createdAt: '2026-05-18T00:00:00Z',
              updatedAt: '2026-05-18T00:00:00Z',
            ),
          );
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId2,
              name: 'Budget 2',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'MM/dd/yyyy',
              createdAt: '2026-05-18T00:00:00Z',
              updatedAt: '2026-05-18T00:00:00Z',
            ),
          );

      // Insert accounts for both budgets
      await dao.upsert(
        AccountsCompanion.insert(
          id: 'account-3a',
          budgetId: budgetId1,
          name: 'Account 1',
          type: AccountType.checking,
          onBudget: true,
          closed: false,
          sortOrder: 2,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:00:00Z',
        ),
      );
      await dao.upsert(
        AccountsCompanion.insert(
          id: 'account-3b',
          budgetId: budgetId1,
          name: 'Account 2',
          type: AccountType.savings,
          onBudget: true,
          closed: false,
          sortOrder: 1,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:00:00Z',
        ),
      );
      await dao.upsert(
        AccountsCompanion.insert(
          id: 'account-3c',
          budgetId: budgetId2,
          name: 'Account 3',
          type: AccountType.cash,
          onBudget: true,
          closed: false,
          sortOrder: 1,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:00:00Z',
        ),
      );

      // Watch budget 1
      final accounts = await dao.watchByBudget(budgetId1).first;

      // Verify correct accounts and ordering
      expect(accounts.length, 2);
      expect(accounts[0].id, 'account-3b'); // sortOrder 1
      expect(accounts[0].name, 'Account 2');
      expect(accounts[1].id, 'account-3a'); // sortOrder 2
      expect(accounts[1].name, 'Account 1');
    });

    test('deleteById removes the row; findById then returns null', () async {
      // Insert parent budget
      const budgetId = 'budget-5';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Test Budget 5',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'MM/dd/yyyy',
              createdAt: '2026-05-18T00:00:00Z',
              updatedAt: '2026-05-18T00:00:00Z',
            ),
          );

      // Upsert an account
      const accountId = 'account-5';
      await dao.upsert(
        AccountsCompanion.insert(
          id: accountId,
          budgetId: budgetId,
          name: 'Checking',
          type: AccountType.checking,
          onBudget: true,
          closed: false,
          sortOrder: 1,
          createdAt: '2026-05-18T00:00:00Z',
          updatedAt: '2026-05-18T00:00:00Z',
        ),
      );

      // Verify it exists
      var row = await dao.findById(accountId);
      expect(row, isNotNull);

      // Delete it
      await dao.deleteById(accountId);

      // Verify it's gone
      row = await dao.findById(accountId);
      expect(row, isNull);
    });

    test('findById for unknown id returns null', () async {
      // Try to find a non-existent account
      final row = await dao.findById('non-existent');
      expect(row, isNull);
    });
  });
}
