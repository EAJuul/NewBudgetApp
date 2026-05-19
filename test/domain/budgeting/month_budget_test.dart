import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/month_budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final line1 = CategoryBudgetLine(
    categoryId: 'cat1',
    assigned: Money(50000),
    activity: Money(-30000),
    available: Money(20000),
  );
  final line2 = CategoryBudgetLine(
    categoryId: 'cat2',
    assigned: Money(20000),
    activity: Money(-10000),
    available: Money(10000),
  );

  MonthBudget buildBudget() => MonthBudget(
        month: MonthKey(2024, 3),
        readyToAssign: Money(5000),
        lines: [line1, line2],
      );

  group('MonthBudget', () {
    test('constructs with correct month, readyToAssign, and lines', () {
      final budget = buildBudget();
      expect(budget.month, MonthKey(2024, 3));
      expect(budget.readyToAssign, Money(5000));
      expect(budget.lines.length, 2);
    });

    test('lineFor returns the matching line', () {
      final budget = buildBudget();
      final line = budget.lineFor('cat1');
      expect(line, isNotNull);
      expect(line!.assigned, Money(50000));
      expect(line.activity, Money(-30000));
      expect(line.available, Money(20000));
    });

    test('lineFor returns null for an unknown category id', () {
      final budget = buildBudget();
      expect(budget.lineFor('unknown'), isNull);
    });

    test('equality: two MonthBudgets with equal lines are ==', () {
      final b1 = buildBudget();
      final b2 = buildBudget();
      expect(b1, equals(b2));
      expect(b1.hashCode, b2.hashCode);
    });

    test('copyWith updates only specified fields', () {
      final budget = buildBudget();
      final updated = budget.copyWith(readyToAssign: Money(99999));
      expect(updated.readyToAssign, Money(99999));
      expect(updated.month, MonthKey(2024, 3));
      expect(updated.lines.length, 2);
    });
  });

  group('CategoryBudgetLine', () {
    test('equality and hashCode as freezed value object', () {
      final l1 = CategoryBudgetLine(
        categoryId: 'cat1',
        assigned: Money(10000),
        activity: Money(-5000),
        available: Money(5000),
      );
      final l2 = CategoryBudgetLine(
        categoryId: 'cat1',
        assigned: Money(10000),
        activity: Money(-5000),
        available: Money(5000),
      );
      expect(l1, equals(l2));
      expect(l1.hashCode, l2.hashCode);
    });
  });
}
