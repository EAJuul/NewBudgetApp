import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/category_available_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCategoryAvailableSeries', () {
    test('one month: available == assigned + activity', () {
      final result = computeCategoryAvailableSeries(
        months: [const MonthKey(2024, 3)],
        assignedFor: (_) => const Money(50000),
        activityFor: (_) => const Money(-30000),
      );
      expect(result[const MonthKey(2024, 3)], const Money(20000));
    });

    test('three contiguous months: month 3 includes months 1-2 carryover', () {
      // Month 1: assigned=50000, activity=-30000 → available=20000
      // Month 2: assigned=50000, activity=-50000 → available=20000
      // Month 3: assigned=50000, activity=-10000 → available=60000
      final months = [
        const MonthKey(2024, 1),
        const MonthKey(2024, 2),
        const MonthKey(2024, 3)
      ];
      final result = computeCategoryAvailableSeries(
        months: months,
        assignedFor: (_) => const Money(50000),
        activityFor: (m) {
          if (m == const MonthKey(2024, 1)) return const Money(-30000);
          if (m == const MonthKey(2024, 2)) return const Money(-50000);
          return const Money(-10000);
        },
      );
      expect(result[const MonthKey(2024, 1)], const Money(20000));
      expect(result[const MonthKey(2024, 2)], const Money(20000));
      expect(result[const MonthKey(2024, 3)], const Money(60000));
    });

    test('assigned only (no activity) and activity only month', () {
      final result = computeCategoryAvailableSeries(
        months: [const MonthKey(2024, 1), const MonthKey(2024, 2)],
        assignedFor: (m) => m == const MonthKey(2024, 1)
            ? const Money(40000)
            : const Money.zero(),
        activityFor: (m) => m == const MonthKey(2024, 2)
            ? const Money(-15000)
            : const Money.zero(),
      );
      // Month 1: 0 + 40000 + 0 = 40000
      expect(result[const MonthKey(2024, 1)], const Money(40000));
      // Month 2: 40000 + 0 + (-15000) = 25000
      expect(result[const MonthKey(2024, 2)], const Money(25000));
    });

    test('negative carryover rolls into next month unchanged (simple mode)',
        () {
      // Month 1: assigned=10000, activity=-50000 → available=-40000
      // Month 2: assigned=10000, activity=0 → available=-30000
      final result = computeCategoryAvailableSeries(
        months: [const MonthKey(2024, 1), const MonthKey(2024, 2)],
        assignedFor: (_) => const Money(10000),
        activityFor: (m) => m == const MonthKey(2024, 1)
            ? const Money(-50000)
            : const Money.zero(),
      );
      expect(result[const MonthKey(2024, 1)], const Money(-40000));
      expect(result[const MonthKey(2024, 2)], const Money(-30000));
    });

    test('negative assigned (money pulled back) reduces available', () {
      // Month 1: assigned=50000, activity=0 → available=50000
      // Month 2: assigned=-20000, activity=0 → available=30000
      final result = computeCategoryAvailableSeries(
        months: [const MonthKey(2024, 1), const MonthKey(2024, 2)],
        assignedFor: (m) => m == const MonthKey(2024, 1)
            ? const Money(50000)
            : const Money(-20000),
        activityFor: (_) => const Money.zero(),
      );
      expect(result[const MonthKey(2024, 1)], const Money(50000));
      expect(result[const MonthKey(2024, 2)], const Money(30000));
    });

    test('empty months returns empty map', () {
      final result = computeCategoryAvailableSeries(
        months: [],
        assignedFor: (_) => const Money.zero(),
        activityFor: (_) => const Money.zero(),
      );
      expect(result, isEmpty);
    });
  });
}
