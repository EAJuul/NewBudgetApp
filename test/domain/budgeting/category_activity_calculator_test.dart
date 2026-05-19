import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/category_activity_calculator.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

void main() {
  group('computeCategoryActivity', () {
    test('one outflow in the month → activity equals that negative amount',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id, name: 'Rent');

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 15),
        amount: const Money(-150000),
        categoryId: cat.id,
      );

      final txns = await fixture.allTransactions();
      final result = computeCategoryActivity(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        transactions: txns,
        subTransactions: [],
      );

      expect(result, const Money(-150000));
    });

    test('two transactions in same month sum; different month excluded',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat =
          await fixture.addCategory(groupId: group.id, name: 'Groceries');

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(-50000),
        categoryId: cat.id,
      );
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 15),
        amount: const Money(-30000),
        categoryId: cat.id,
      );
      // Different month — should be excluded
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 4),
        amount: const Money(-99999),
        categoryId: cat.id,
      );

      final txns = await fixture.allTransactions();
      final result = computeCategoryActivity(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        transactions: txns,
        subTransactions: [],
      );

      expect(result, const Money(-80000)); // -50000 + -30000
    });

    test('split transaction: each category gets only its sub-amount', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat1 = await fixture.addCategory(groupId: group.id, name: 'Cat1');
      final cat2 = await fixture.addCategory(groupId: group.id, name: 'Cat2');

      final tx = await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 10),
        amount: const Money(-100000),
        isSplit: true,
        subTransactions: [
          SubTransaction(
            id: 'sub1',
            transactionId: 'placeholder',
            amount: const Money(-60000),
            deleted: false,
            categoryId: cat1.id,
          ),
          SubTransaction(
            id: 'sub2',
            transactionId: 'placeholder',
            amount: const Money(-40000),
            deleted: false,
            categoryId: cat2.id,
          ),
        ],
      );

      final txns = await fixture.allTransactions();
      final subs = await fixture.subTransactionsOf(tx.id);

      final result1 = computeCategoryActivity(
        categoryId: cat1.id,
        month: const MonthKey(2024, 3),
        transactions: txns,
        subTransactions: subs,
      );
      final result2 = computeCategoryActivity(
        categoryId: cat2.id,
        month: const MonthKey(2024, 3),
        transactions: txns,
        subTransactions: subs,
      );

      expect(result1, const Money(-60000));
      expect(result2, const Money(-40000));
    });

    test('deleted transaction and deleted sub-transaction are excluded',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id, name: 'Cat');

      final toDelete = await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(-99999),
        categoryId: cat.id,
      );
      await fixture.transactions.softDelete(toDelete.id);

      // Simulate deleted transaction in the list
      final deletedTx = toDelete.copyWith(deleted: true);

      final result = computeCategoryActivity(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        transactions: [deletedTx],
        subTransactions: [],
      );

      expect(result, const Money.zero());
    });

    test('sub-transaction whose parent is deleted is excluded', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id, name: 'Cat');

      final tx = await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 5),
        amount: const Money(-50000),
        isSplit: true,
        subTransactions: [
          SubTransaction(
            id: 'sub1',
            transactionId: 'placeholder',
            amount: const Money(-50000),
            deleted: false,
            categoryId: cat.id,
          ),
        ],
      );

      // Simulate the parent being deleted
      final deletedParent = tx.copyWith(deleted: true);
      final subs = await fixture.subTransactionsOf(tx.id);

      final result = computeCategoryActivity(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        transactions: [deletedParent],
        subTransactions: subs,
      );

      expect(result, const Money.zero());
    });

    test('inflow (positive amount) produces positive activity', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id, name: 'Income');

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(250000),
        categoryId: cat.id,
      );

      final txns = await fixture.allTransactions();
      final result = computeCategoryActivity(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        transactions: txns,
        subTransactions: [],
      );

      expect(result, const Money(250000));
    });
  });
}
