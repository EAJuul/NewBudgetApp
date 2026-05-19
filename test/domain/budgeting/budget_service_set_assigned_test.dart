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
  group('BudgetService.setAssigned', () {
    test(
      'creates a new assignment row and computeMonth shows correct assigned and reduced RTA',
      () async {
        final fixture = await BudgetFixture.create();
        addTearDown(fixture.dispose);

        final group = await fixture.addGroup();
        final category = await fixture.addCategory(groupId: group.id);

        final service = _serviceFrom(fixture);
        const month = MonthKey(2025, 1);
        const assignedAmount = Money(50000); // $50.00

        // Initially no assignment
        final monthBefore = await service.computeMonth(fixture.budgetId, month);
        final categoryLineBefore = monthBefore.lines
            .firstWhere((line) => line.categoryId == category.id);
        expect(categoryLineBefore.assigned, const Money.zero());

        // Set assigned
        await service.setAssigned(
          categoryId: category.id,
          month: month,
          amount: assignedAmount,
        );

        // Verify assignment created and RTA reduced
        final monthAfter = await service.computeMonth(fixture.budgetId, month);
        final categoryLineAfter = monthAfter.lines
            .firstWhere((line) => line.categoryId == category.id);
        expect(categoryLineAfter.assigned, assignedAmount);
        expect(
          monthAfter.readyToAssign,
          lessThan(monthBefore.readyToAssign),
        );
      },
    );

    test(
      'replaces an existing assignment without adding to it',
      () async {
        final fixture = await BudgetFixture.create();
        addTearDown(fixture.dispose);

        final group = await fixture.addGroup();
        final category = await fixture.addCategory(groupId: group.id);

        const month = MonthKey(2025, 1);
        const initialAmount = Money(30000); // $30.00
        const newAmount = Money(50000); // $50.00

        // Create initial assignment
        await fixture.assign(
          categoryId: category.id,
          month: month,
          amount: initialAmount,
        );

        final service = _serviceFrom(fixture);

        // Verify initial assignment
        var monthBudget = await service.computeMonth(fixture.budgetId, month);
        var categoryLine = monthBudget.lines
            .firstWhere((line) => line.categoryId == category.id);
        expect(categoryLine.assigned, initialAmount);

        // Set new amount
        await service.setAssigned(
          categoryId: category.id,
          month: month,
          amount: newAmount,
        );

        // Verify it replaced, not added
        monthBudget = await service.computeMonth(fixture.budgetId, month);
        categoryLine = monthBudget.lines
            .firstWhere((line) => line.categoryId == category.id);
        expect(categoryLine.assigned, newAmount);
      },
    );

    test(
      'setAssigned to zero returns money to RTA',
      () async {
        final fixture = await BudgetFixture.create();
        addTearDown(fixture.dispose);

        final group = await fixture.addGroup();
        final category = await fixture.addCategory(groupId: group.id);

        const month = MonthKey(2025, 1);
        const amount = Money(50000); // $50.00

        // Create initial assignment
        await fixture.assign(
          categoryId: category.id,
          month: month,
          amount: amount,
        );

        final service = _serviceFrom(fixture);

        // RTA before zeroing
        var monthBudget = await service.computeMonth(fixture.budgetId, month);
        final rtaBefore = monthBudget.readyToAssign;

        // Zero the assignment
        await service.setAssigned(
          categoryId: category.id,
          month: month,
          amount: const Money.zero(),
        );

        // RTA should increase
        monthBudget = await service.computeMonth(fixture.budgetId, month);
        final rtaAfter = monthBudget.readyToAssign;
        expect(rtaAfter, greaterThan(rtaBefore));

        final categoryLine = monthBudget.lines
            .firstWhere((line) => line.categoryId == category.id);
        expect(categoryLine.assigned, const Money.zero());
      },
    );

    test(
      'setAssigned to negative amount stores it and raises RTA',
      () async {
        final fixture = await BudgetFixture.create();
        addTearDown(fixture.dispose);

        final group = await fixture.addGroup();
        final category = await fixture.addCategory(groupId: group.id);

        const month = MonthKey(2025, 1);
        const negativeAmount = Money(-25000); // -$25.00

        final service = _serviceFrom(fixture);

        // RTA before negative assignment
        var monthBudget = await service.computeMonth(fixture.budgetId, month);
        final rtaBefore = monthBudget.readyToAssign;

        // Set negative amount
        await service.setAssigned(
          categoryId: category.id,
          month: month,
          amount: negativeAmount,
        );

        // Verify negative value stored and RTA raised
        monthBudget = await service.computeMonth(fixture.budgetId, month);
        final rtaAfter = monthBudget.readyToAssign;
        final categoryLine = monthBudget.lines
            .firstWhere((line) => line.categoryId == category.id);
        expect(categoryLine.assigned, negativeAmount);
        expect(rtaAfter, greaterThan(rtaBefore));
      },
    );

    test(
      'setting one month does not change another month',
      () async {
        final fixture = await BudgetFixture.create();
        addTearDown(fixture.dispose);

        final group = await fixture.addGroup();
        final category = await fixture.addCategory(groupId: group.id);

        const month1 = MonthKey(2025, 1);
        const month2 = MonthKey(2025, 2);
        const amount1 = Money(40000); // $40.00
        const amount2 = Money(60000); // $60.00

        // Create assignments for both months
        await fixture.assign(
          categoryId: category.id,
          month: month1,
          amount: amount1,
        );
        await fixture.assign(
          categoryId: category.id,
          month: month2,
          amount: amount2,
        );

        final service = _serviceFrom(fixture);

        // Change month1
        const newAmount1 = Money(100000); // $100.00
        await service.setAssigned(
          categoryId: category.id,
          month: month1,
          amount: newAmount1,
        );

        // Verify month1 changed
        var monthBudget = await service.computeMonth(fixture.budgetId, month1);
        var categoryLine =
            monthBudget.lines.firstWhere((l) => l.categoryId == category.id);
        expect(categoryLine.assigned, newAmount1);

        // Verify month2 unchanged
        monthBudget = await service.computeMonth(fixture.budgetId, month2);
        categoryLine =
            monthBudget.lines.firstWhere((l) => l.categoryId == category.id);
        expect(categoryLine.assigned, amount2);
      },
    );
  });
}
