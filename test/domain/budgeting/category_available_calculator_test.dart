import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/category_available_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCategoryAvailableSeries', () {
    test('one month: available == assigned + activity', () {
      final result = computeCategoryAvailableSeries(
        months: [MonthKey(2024, 3)],
        assignedFor: (_) => Money(50000),
        activityFor: (_) => Money(-30000),
      );
      expect(result[MonthKey(2024, 3)], Money(20000));
    });

    test('three contiguous months: month 3 includes months 1-2 carryover', () {
      // Month 1: assigned=50000, activity=-30000 → available=20000
      // Month 2: assigned=50000, activity=-50000 → available=20000
      // Month 3: assigned=50000, activity=-10000 → available=60000
      final months = [MonthKey(2024, 1), MonthKey(2024, 2), MonthKey(2024, 3)];
      final result = computeCategoryAvailableSeries(
        months: months,
        assignedFor: (_) => Money(50000),
        activityFor: (m) {
          if (m == MonthKey(2024, 1)) return Money(-30000);
          if (m == MonthKey(2024, 2)) return Money(-50000);
          return Money(-10000);
        },
      );
      expect(result[MonthKey(2024, 1)], Money(20000));
      expect(result[MonthKey(2024, 2)], Money(20000));
      expect(result[MonthKey(2024, 3)], Money(60000));
    });

    test('assigned only (no activity) and activity only month', () {
      final result = computeCategoryAvailableSeries(
        months: [MonthKey(2024, 1), MonthKey(2024, 2)],
        assignedFor: (m) =>
            m == MonthKey(2024, 1) ? Money(40000) : Money.zero(),
        activityFor: (m) =>
            m == MonthKey(2024, 2) ? Money(-15000) : Money.zero(),
      );
      // Month 1: 0 + 40000 + 0 = 40000
      expect(result[MonthKey(2024, 1)], Money(40000));
      // Month 2: 40000 + 0 + (-15000) = 25000
      expect(result[MonthKey(2024, 2)], Money(25000));
    });

    test('negative carryover rolls into next month unchanged (simple mode)',
        () {
      // Month 1: assigned=10000, activity=-50000 → available=-40000
      // Month 2: assigned=10000, activity=0 → available=-30000
      final result = computeCategoryAvailableSeries(
        months: [MonthKey(2024, 1), MonthKey(2024, 2)],
        assignedFor: (_) => Money(10000),
        activityFor: (m) =>
            m == MonthKey(2024, 1) ? Money(-50000) : Money.zero(),
      );
      expect(result[MonthKey(2024, 1)], Money(-40000));
      expect(result[MonthKey(2024, 2)], Money(-30000));
    });

    test('negative assigned (money pulled back) reduces available', () {
      // Month 1: assigned=50000, activity=0 → available=50000
      // Month 2: assigned=-20000, activity=0 → available=30000
      final result = computeCategoryAvailableSeries(
        months: [MonthKey(2024, 1), MonthKey(2024, 2)],
        assignedFor: (m) =>
            m == MonthKey(2024, 1) ? Money(50000) : Money(-20000),
        activityFor: (_) => Money.zero(),
      );
      expect(result[MonthKey(2024, 1)], Money(50000));
      expect(result[MonthKey(2024, 2)], Money(30000));
    });

    test('empty months returns empty map', () {
      final result = computeCategoryAvailableSeries(
        months: [],
        assignedFor: (_) => Money.zero(),
        activityFor: (_) => Money.zero(),
      );
      expect(result, isEmpty);
    });
  });
}
