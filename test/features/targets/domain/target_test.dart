import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Target', () {
    test('constructs monthlyFunding target with null targetMonth', () {
      const target = Target(
        id: 't1',
        categoryId: 'cat1',
        type: TargetType.monthlyFunding,
        amount: Money(50000),
      );
      expect(target.id, 't1');
      expect(target.categoryId, 'cat1');
      expect(target.type, TargetType.monthlyFunding);
      expect(target.amount, const Money(50000));
      expect(target.targetMonth, isNull);
    });

    test('constructs targetBalanceByDate target with non-null targetMonth', () {
      const target = Target(
        id: 't2',
        categoryId: 'cat1',
        type: TargetType.targetBalanceByDate,
        amount: Money(500000),
        targetMonth: MonthKey(2024, 12),
      );
      expect(target.targetMonth, const MonthKey(2024, 12));
      expect(target.type, TargetType.targetBalanceByDate);
    });

    test('constructs targetBalance and monthlySpending targets', () {
      const t1 = Target(
        id: 't3',
        categoryId: 'cat2',
        type: TargetType.targetBalance,
        amount: Money(200000),
      );
      const t2 = Target(
        id: 't4',
        categoryId: 'cat3',
        type: TargetType.monthlySpending,
        amount: Money(100000),
      );
      expect(t1.type, TargetType.targetBalance);
      expect(t2.type, TargetType.monthlySpending);
    });

    test('equality and hashCode as value object', () {
      const t1 = Target(
        id: 't1',
        categoryId: 'cat1',
        type: TargetType.monthlyFunding,
        amount: Money(50000),
      );
      const t2 = Target(
        id: 't1',
        categoryId: 'cat1',
        type: TargetType.monthlyFunding,
        amount: Money(50000),
      );
      expect(t1, equals(t2));
      expect(t1.hashCode, t2.hashCode);
    });

    test('copyWith updates only specified fields', () {
      const t = Target(
        id: 't1',
        categoryId: 'cat1',
        type: TargetType.monthlyFunding,
        amount: Money(50000),
      );
      final updated = t.copyWith(amount: const Money(75000));
      expect(updated.id, 't1');
      expect(updated.amount, const Money(75000));
      expect(updated.type, TargetType.monthlyFunding);
    });
  });
}
