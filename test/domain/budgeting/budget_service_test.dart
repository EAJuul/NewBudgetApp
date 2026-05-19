import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/budget_service.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

BudgetService _serviceFrom(BudgetFixture fixture) => BudgetService(
      accountRepository: fixture.accounts,
      categoryRepository: fixture.categories,
      categoryBudgetRepository: fixture.categoryBudgets,
      transactionRepository: fixture.transactions,
    );

void main() {
  group('BudgetService.computeMonth', () {
    test('empty budget returns MonthBudget with zero RTA and no lines',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);
      final service = _serviceFrom(fixture);

      final result = await service.computeMonth(
        fixture.budgetId,
        const MonthKey(2024, 3),
      );

      expect(result.readyToAssign, const Money.zero());
      expect(result.lines, isEmpty);
    });

    test(
        'one funded category with one outflow: correct assigned, activity, available, and RTA',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      // Inflow to RTA (uncategorised)
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(100000),
      );

      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id, name: 'Rent');
      await fixture.assign(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        amount: const Money(60000),
      );
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 15),
        amount: const Money(-50000),
        categoryId: cat.id,
      );

      final service = _serviceFrom(fixture);
      final result =
          await service.computeMonth(fixture.budgetId, const MonthKey(2024, 3));

      // RTA = 100000 inflow - 60000 assigned = 40000
      expect(result.readyToAssign, const Money(40000));

      final line = result.lineFor(cat.id);
      expect(line, isNotNull);
      expect(line!.assigned, const Money(60000));
      expect(line.activity, const Money(-50000));
      // available = 0 (carry) + 60000 (assigned) + (-50000) (activity) = 10000
      expect(line.available, const Money(10000));
    });

    test('rollover: assign in month 1, view month 2 includes carryover',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024),
        amount: const Money(200000),
      );

      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id, name: 'Savings');
      // Assign 50000 in month 1, no activity
      await fixture.assign(
        categoryId: cat.id,
        month: const MonthKey(2024, 1),
        amount: const Money(50000),
      );
      // Assign 10000 in month 2
      await fixture.assign(
        categoryId: cat.id,
        month: const MonthKey(2024, 2),
        amount: const Money(10000),
      );

      final service = _serviceFrom(fixture);
      final result =
          await service.computeMonth(fixture.budgetId, const MonthKey(2024, 2));

      final line = result.lineFor(cat.id);
      expect(line, isNotNull);
      // available(month2) = available(month1) + assigned(month2) + activity(month2)
      //   = 50000 + 10000 + 0 = 60000
      expect(line!.available, const Money(60000));
    });

    test('split transaction contributes to correct category lines', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(200000),
      );

      final group = await fixture.addGroup();
      final cat1 = await fixture.addCategory(groupId: group.id, name: 'Cat1');
      final cat2 = await fixture.addCategory(groupId: group.id, name: 'Cat2');

      await fixture.assign(
          categoryId: cat1.id, month: const MonthKey(2024, 3), amount: const Money(100000),);
      await fixture.assign(
          categoryId: cat2.id, month: const MonthKey(2024, 3), amount: const Money(100000),);

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 10),
        amount: const Money(-150000),
        isSplit: true,
        subTransactions: [
          SubTransaction(
            id: 'sub1',
            transactionId: 'placeholder',
            amount: const Money(-90000),
            deleted: false,
            categoryId: cat1.id,
          ),
          SubTransaction(
            id: 'sub2',
            transactionId: 'placeholder',
            amount: const Money(-60000),
            deleted: false,
            categoryId: cat2.id,
          ),
        ],
      );

      final service = _serviceFrom(fixture);
      final result =
          await service.computeMonth(fixture.budgetId, const MonthKey(2024, 3));

      final line1 = result.lineFor(cat1.id);
      final line2 = result.lineFor(cat2.id);

      expect(line1!.activity, const Money(-90000));
      expect(line2!.activity, const Money(-60000));
      // available = assigned + activity
      expect(line1.available, const Money(10000)); // 100000 - 90000
      expect(line2.available, const Money(40000)); // 100000 - 60000
    });

    test('computeMonth for a month with no data returns valid MonthBudget',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final service = _serviceFrom(fixture);
      final result =
          await service.computeMonth(fixture.budgetId, const MonthKey(2099, 12));

      expect(result.month, const MonthKey(2099, 12));
      expect(result.readyToAssign, const Money.zero());
      expect(result.lines, isEmpty);
    });
  });
}
