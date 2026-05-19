import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryBudget', () {
    test('constructs with all fields', () {
      const id = 'budget-123';
      const categoryId = 'cat-456';
      const month = MonthKey(2026, 5);
      const assigned = Money(50000);

      const budget = CategoryBudget(
        id: id,
        categoryId: categoryId,
        month: month,
        assigned: assigned,
      );

      expect(budget.id, id);
      expect(budget.categoryId, categoryId);
      expect(budget.month, month);
      expect(budget.month.toIso(), '2026-05');
      expect(budget.assigned, assigned);
      expect(budget.assigned.milliunits, 50000);
    });

    test('copyWith returns updated copy with original unchanged', () {
      const original = CategoryBudget(
        id: 'budget-123',
        categoryId: 'cat-456',
        month: MonthKey(2026, 5),
        assigned: Money(50000),
      );

      const newAssigned = Money(-5000);
      final updated = original.copyWith(assigned: newAssigned);

      expect(updated.assigned, newAssigned);
      expect(updated.id, original.id);
      expect(updated.categoryId, original.categoryId);
      expect(updated.month, original.month);
      expect(original.assigned, const Money(50000));
    });

    test('equality: identical fields are equal with same hashCode', () {
      const budget1 = CategoryBudget(
        id: 'budget-123',
        categoryId: 'cat-456',
        month: MonthKey(2026, 5),
        assigned: Money(50000),
      );

      const budget2 = CategoryBudget(
        id: 'budget-123',
        categoryId: 'cat-456',
        month: MonthKey(2026, 5),
        assigned: Money(50000),
      );

      expect(budget1, budget2);
      expect(budget1.hashCode, budget2.hashCode);
    });

    test('equality: differing id means not equal', () {
      const budget1 = CategoryBudget(
        id: 'budget-123',
        categoryId: 'cat-456',
        month: MonthKey(2026, 5),
        assigned: Money(50000),
      );

      const budget2 = CategoryBudget(
        id: 'budget-999',
        categoryId: 'cat-456',
        month: MonthKey(2026, 5),
        assigned: Money(50000),
      );

      expect(budget1, isNot(budget2));
    });
  });
}
