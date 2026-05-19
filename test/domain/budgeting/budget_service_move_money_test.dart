import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/budget_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

BudgetService _serviceFrom(BudgetFixture fixture) => BudgetService(
      accountRepository: fixture.accounts,
      categoryRepository: fixture.categories,
      categoryBudgetRepository: fixture.categoryBudgets,
      transactionRepository: fixture.transactions,
    );

void main() {
  group('BudgetService.moveMoney', () {
    test(
        'move between two categories with existing assignments: each assigned changes by amount',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final group = await fixture.addGroup();
      final from = await fixture.addCategory(groupId: group.id, name: 'From');
      final to = await fixture.addCategory(groupId: group.id, name: 'To');

      const month = MonthKey(2024, 3);
      const moveAmount = Money(30000);

      // Create initial assignments
      await fixture.assign(
        categoryId: from.id,
        month: month,
        amount: const Money(100000),
      );
      await fixture.assign(
        categoryId: to.id,
        month: month,
        amount: const Money(50000),
      );

      // Create account and transaction for RTA calculation
      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(200000),
      );

      final service = _serviceFrom(fixture);

      // Move money
      await service.moveMoney(
        fromCategoryId: from.id,
        toCategoryId: to.id,
        month: month,
        amount: moveAmount,
      );

      // Verify assignments changed by exactly the amount
      final fromBudget = await fixture.categoryBudgets.find(from.id, month);
      final toBudget = await fixture.categoryBudgets.find(to.id, month);

      expect(fromBudget!.assigned, const Money(70000)); // 100000 - 30000
      expect(toBudget!.assigned, const Money(80000)); // 50000 + 30000

      // Verify readyToAssign unchanged (move is zero-sum)
      final monthBudget = await service.computeMonth(fixture.budgetId, month);
      expect(
        monthBudget.readyToAssign,
        const Money(
            50000,), // 200000 - 100000 - 50000 = 50000, unchanged by move
      );
    });

    test(
        'move into category with no prior assignment creates new CategoryBudget',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final group = await fixture.addGroup();
      final from = await fixture.addCategory(groupId: group.id, name: 'From');
      final to = await fixture.addCategory(groupId: group.id, name: 'To');

      const month = MonthKey(2024, 3);
      const moveAmount = Money(30000);

      // Only 'from' has an assignment
      await fixture.assign(
        categoryId: from.id,
        month: month,
        amount: const Money(100000),
      );

      final service = _serviceFrom(fixture);

      // Move money
      await service.moveMoney(
        fromCategoryId: from.id,
        toCategoryId: to.id,
        month: month,
        amount: moveAmount,
      );

      // Verify 'to' now has a new assignment with assigned == amount
      final toBudget = await fixture.categoryBudgets.find(to.id, month);

      expect(toBudget, isNotNull);
      expect(toBudget!.categoryId, to.id);
      expect(toBudget.month, month);
      expect(toBudget.assigned, moveAmount);
    });

    test('move more than source holds: source assigned goes negative',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final group = await fixture.addGroup();
      final from = await fixture.addCategory(groupId: group.id, name: 'From');
      final to = await fixture.addCategory(groupId: group.id, name: 'To');

      const month = MonthKey(2024, 3);
      const moveAmount = Money(60000);

      // 'from' has only 50000
      await fixture.assign(
        categoryId: from.id,
        month: month,
        amount: const Money(50000),
      );
      await fixture.assign(
        categoryId: to.id,
        month: month,
        amount: const Money(20000),
      );

      final service = _serviceFrom(fixture);

      // Move more than source holds
      await service.moveMoney(
        fromCategoryId: from.id,
        toCategoryId: to.id,
        month: month,
        amount: moveAmount,
      );

      // Verify 'from' went negative
      final fromBudget = await fixture.categoryBudgets.find(from.id, month);
      final toBudget = await fixture.categoryBudgets.find(to.id, month);

      expect(
          fromBudget!.assigned, const Money(-10000),); // 50000 - 60000 = -10000
      expect(toBudget!.assigned, const Money(80000)); // 20000 + 60000
    });

    test('move affects only specified month, other months untouched', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final group = await fixture.addGroup();
      final from = await fixture.addCategory(groupId: group.id, name: 'From');
      final to = await fixture.addCategory(groupId: group.id, name: 'To');

      const month1 = MonthKey(2024, 1);
      const month2 = MonthKey(2024, 2);
      const moveMonth = MonthKey(2024, 2);
      const moveAmount = Money(20000);

      // Assign in both months
      await fixture.assign(
        categoryId: from.id,
        month: month1,
        amount: const Money(100000),
      );
      await fixture.assign(
        categoryId: from.id,
        month: month2,
        amount: const Money(80000),
      );
      await fixture.assign(
        categoryId: to.id,
        month: month1,
        amount: const Money(50000),
      );
      await fixture.assign(
        categoryId: to.id,
        month: month2,
        amount: const Money(40000),
      );

      final service = _serviceFrom(fixture);

      // Move only in month 2
      await service.moveMoney(
        fromCategoryId: from.id,
        toCategoryId: to.id,
        month: moveMonth,
        amount: moveAmount,
      );

      // Verify month 1 untouched
      final fromMonth1 = await fixture.categoryBudgets.find(from.id, month1);
      final toMonth1 = await fixture.categoryBudgets.find(to.id, month1);
      expect(fromMonth1!.assigned, const Money(100000));
      expect(toMonth1!.assigned, const Money(50000));

      // Verify month 2 changed
      final fromMonth2 = await fixture.categoryBudgets.find(from.id, month2);
      final toMonth2 = await fixture.categoryBudgets.find(to.id, month2);
      expect(fromMonth2!.assigned, const Money(60000)); // 80000 - 20000
      expect(toMonth2!.assigned, const Money(60000)); // 40000 + 20000
    });
  });
}
