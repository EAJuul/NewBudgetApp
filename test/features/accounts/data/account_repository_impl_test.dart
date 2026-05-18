import 'package:budget_app/data/daos/accounts_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/data/account_repository_impl.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountRepositoryImpl', () {
    late AppDatabase db;
    late AccountRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = AccountRepositoryImpl(db);

      // Seed a budget for tests
      await db.into(db.budgets).insert(
            BudgetsCompanion(
              id: const Value('budget-1'),
              name: const Value('Test Budget'),
              currencyCode: const Value('USD'),
              currencyDecimalDigits: const Value(2),
              dateFormat: const Value('MM/dd/yyyy'),
              createdAt: Value(DateTime.now().toUtc().toIso8601String()),
              updatedAt: Value(DateTime.now().toUtc().toIso8601String()),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'save then findById returns the saved account as a domain Account entity',
        () async {
      const account = Account(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        note: 'My checking account',
        sortOrder: 1,
      );

      await repository.save(account);
      final retrieved = await repository.findById('acc-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'acc-1');
      expect(retrieved.budgetId, 'budget-1');
      expect(retrieved.name, 'Checking');
      expect(retrieved.type, AccountType.checking);
      expect(retrieved.onBudget, isTrue);
      expect(retrieved.closed, isFalse);
      expect(retrieved.note, 'My checking account');
      expect(retrieved.sortOrder, 1);
    });

    test(
        'save twice with same id (changed name) updates the row and preserves original createdAt',
        () async {
      const account1 = Account(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
      );

      await repository.save(account1);

      // Get the createdAt timestamp from the first save
      final dao = AccountsDao(db);
      final row1 = await dao.findById('acc-1');
      final firstCreatedAt = row1!.createdAt;

      // Wait a tiny bit to ensure timestamps differ if they were regenerated
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const account2 = Account(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Updated Checking', // changed
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
      );

      await repository.save(account2);

      // Verify the name was updated
      final retrieved = await repository.findById('acc-1');
      expect(retrieved!.name, 'Updated Checking');

      // Verify createdAt is preserved
      final row2 = await dao.findById('acc-1');
      expect(row2!.createdAt, firstCreatedAt);
    });

    test("watchAll emits the budget's accounts as Account entities", () async {
      const account1 = Account(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
      );

      const account2 = Account(
        id: 'acc-2',
        budgetId: 'budget-1',
        name: 'Savings',
        type: AccountType.savings,
        onBudget: true,
        closed: false,
        sortOrder: 2,
      );

      await repository.save(account1);
      await repository.save(account2);

      final accounts = await repository.watchAll('budget-1').first;

      expect(accounts, hasLength(2));
      expect(accounts[0].id, 'acc-1');
      expect(accounts[0].name, 'Checking');
      expect(accounts[1].id, 'acc-2');
      expect(accounts[1].name, 'Savings');
    });

    test('delete removes the account and findById returns null', () async {
      const account = Account(
        id: 'acc-1',
        budgetId: 'budget-1',
        name: 'Checking',
        type: AccountType.checking,
        onBudget: true,
        closed: false,
        sortOrder: 1,
      );

      await repository.save(account);
      final retrieved = await repository.findById('acc-1');
      expect(retrieved, isNotNull);

      await repository.delete('acc-1');
      final deleted = await repository.findById('acc-1');
      expect(deleted, isNull);
    });
  });
}
