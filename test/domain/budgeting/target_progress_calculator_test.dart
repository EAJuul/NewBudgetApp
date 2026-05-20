import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/target_progress_calculator.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:flutter_test/flutter_test.dart';

Target _target(TargetType type, int milliunits, {MonthKey? targetMonth}) =>
    Target(
      id: 'tgt-1',
      categoryId: 'cat-1',
      type: type,
      amount: Money(milliunits),
      targetMonth: targetMonth,
    );

void main() {
  group('computeTargetProgress — monthlyFunding', () {
    test('under-assigned: needed is the gap, isMet false', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.monthlyFunding, 50000),
        month: const MonthKey(2024, 3),
        assigned: const Money(30000),
        available: const Money(30000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(20000));
    });

    test('exactly assigned: needed zero, isMet true', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.monthlyFunding, 50000),
        month: const MonthKey(2024, 3),
        assigned: const Money(50000),
        available: const Money(50000),
      );
      expect(progress.isMet, isTrue);
      expect(progress.needed, const Money.zero());
    });

    test('over-assigned: isMet true, needed zero', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.monthlyFunding, 50000),
        month: const MonthKey(2024, 3),
        assigned: const Money(70000),
        available: const Money(70000),
      );
      expect(progress.isMet, isTrue);
      expect(progress.needed, const Money.zero());
    });

    test('uses assigned not available: rollover does not count', () {
      // available = 80000 (rollover included), but assigned this month = 20000
      final progress = computeTargetProgress(
        target: _target(TargetType.monthlyFunding, 50000),
        month: const MonthKey(2024, 3),
        assigned: const Money(20000),
        available: const Money(80000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(30000));
    });
  });

  group('computeTargetProgress — monthlySpending', () {
    test('available with rollover meets target even with zero assigned', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.monthlySpending, 50000),
        month: const MonthKey(2024, 3),
        assigned: const Money.zero(),
        available: const Money(60000),
      );
      expect(progress.isMet, isTrue);
      expect(progress.needed, const Money.zero());
    });

    test('available below target: needed is gap', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.monthlySpending, 50000),
        month: const MonthKey(2024, 3),
        assigned: const Money(30000),
        available: const Money(30000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(20000));
    });
  });

  group('computeTargetProgress — targetBalance', () {
    test('available below target', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.targetBalance, 100000),
        month: const MonthKey(2024, 3),
        assigned: const Money(40000),
        available: const Money(40000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(60000));
    });

    test('available equals target', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.targetBalance, 100000),
        month: const MonthKey(2024, 3),
        assigned: const Money(100000),
        available: const Money(100000),
      );
      expect(progress.isMet, isTrue);
      expect(progress.needed, const Money.zero());
    });

    test('available above target', () {
      final progress = computeTargetProgress(
        target: _target(TargetType.targetBalance, 100000),
        month: const MonthKey(2024, 3),
        assigned: const Money(120000),
        available: const Money(120000),
      );
      expect(progress.isMet, isTrue);
      expect(progress.needed, const Money.zero());
    });
  });

  group('computeTargetProgress — targetBalanceByDate', () {
    test('needed is ceiled remainder over months left', () {
      // Target 100000, available 10000 → remaining 90000, 4 months left
      // ceil(90000 / 4) = 22500 (divides evenly)
      final progress = computeTargetProgress(
        target: _target(
          TargetType.targetBalanceByDate,
          100000,
          targetMonth: const MonthKey(2024, 7),
        ),
        month: const MonthKey(2024, 3),
        assigned: const Money(10000),
        available: const Money(10000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(22500)); // 90000 / 4
    });

    test('ceil division: non-divisible remainder rounds up', () {
      // Target 100000, available 0 → remaining 100000, 3 months left
      // ceil(100000 / 3) = 33334
      final progress = computeTargetProgress(
        target: _target(
          TargetType.targetBalanceByDate,
          100000,
          targetMonth: const MonthKey(2024, 6),
        ),
        month: const MonthKey(2024, 3),
        assigned: const Money.zero(),
        available: const Money.zero(),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(33334)); // ceil(100000/3)
    });

    test('monthsLeft clamps to 1 when month is at targetMonth', () {
      // month == targetMonth → monthsLeft = max(0,1) = 1
      // remaining 50000 / 1 = 50000
      final progress = computeTargetProgress(
        target: _target(
          TargetType.targetBalanceByDate,
          100000,
          targetMonth: const MonthKey(2024, 3),
        ),
        month: const MonthKey(2024, 3),
        assigned: const Money(50000),
        available: const Money(50000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(50000));
    });

    test('monthsLeft clamps to 1 when month is past targetMonth', () {
      // month > targetMonth → monthsLeft clamps to 1
      final progress = computeTargetProgress(
        target: _target(
          TargetType.targetBalanceByDate,
          100000,
          targetMonth: const MonthKey(2024, 1),
        ),
        month: const MonthKey(2024, 6),
        assigned: const Money(60000),
        available: const Money(60000),
      );
      expect(progress.isMet, isFalse);
      expect(progress.needed, const Money(40000)); // 40000 / 1
    });

    test('already met: needed zero, isMet true', () {
      final progress = computeTargetProgress(
        target: _target(
          TargetType.targetBalanceByDate,
          100000,
          targetMonth: const MonthKey(2024, 6),
        ),
        month: const MonthKey(2024, 3),
        assigned: const Money(100000),
        available: const Money(100000),
      );
      expect(progress.isMet, isTrue);
      expect(progress.needed, const Money.zero());
    });
  });
}
