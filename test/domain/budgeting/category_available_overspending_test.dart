import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/category_available_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCategoryAvailableSeries — overspending rules', () {
    const jan = MonthKey(2024, 1);
    const feb = MonthKey(2024, 2);
    const mar = MonthKey(2024, 3);

    test('simple mode: negative available rolls fully into next month', () {
      // Jan: 0 + 30 + (-50) = -20; Feb: -20 + 30 + 0 = 10
      final result = computeCategoryAvailableSeries(
        months: [jan, feb],
        assignedFor: (m) => m == jan ? const Money(30000) : const Money(30000),
        activityFor: (m) => m == jan ? const Money(-50000) : const Money.zero(),
      );

      expect(result[jan], const Money(-20000));
      expect(result[feb], const Money(10000)); // -20 carried forward
    });

    test('cash overspending: negative carryover is dropped (zero rolls forward)',
        () {
      // Jan: 0 + 30 + (-50) = -20; creditOverspent(jan)=0 (all cash)
      // Feb carryover = max(-20, -0) = 0 → Feb: 0 + 30 + 0 = 30
      final result = computeCategoryAvailableSeries(
        months: [jan, feb],
        assignedFor: (_) => const Money(30000),
        activityFor: (m) => m == jan ? const Money(-50000) : const Money.zero(),
        creditOverspentFor: (_) => const Money.zero(),
      );

      expect(result[jan], const Money(-20000));
      expect(result[feb], const Money(30000)); // carryover was clamped to 0
    });

    test(
        'credit overspending: full negative rolls forward when all overspend is credit',
        () {
      // Jan: 0 + 30 + (-50) = -20; creditOverspent(jan)=20 (all credit)
      // Feb carryover = max(-20, -20) = -20 → Feb: -20 + 30 + 0 = 10
      final result = computeCategoryAvailableSeries(
        months: [jan, feb],
        assignedFor: (_) => const Money(30000),
        activityFor: (m) => m == jan ? const Money(-50000) : const Money.zero(),
        creditOverspentFor: (m) =>
            m == jan ? const Money(20000) : const Money.zero(),
      );

      expect(result[jan], const Money(-20000));
      expect(result[feb], const Money(10000)); // full -20 carried forward
    });

    test(
        'mixed overspending: only credit portion rolls forward, cash portion dropped',
        () {
      // Jan: 0 + 20 + (-50) = -30 overspend; creditOverspent(jan)=10 (partial)
      // Feb carryover = max(-30, -10) = -10 → Feb: -10 + 20 + 0 = 10
      final result = computeCategoryAvailableSeries(
        months: [jan, feb],
        assignedFor: (_) => const Money(20000),
        activityFor: (m) => m == jan ? const Money(-50000) : const Money.zero(),
        creditOverspentFor: (m) =>
            m == jan ? const Money(10000) : const Money.zero(),
      );

      expect(result[jan], const Money(-30000));
      expect(result[feb], const Money(10000)); // only -10 carried forward
    });

    test('positive available is unaffected by creditOverspentFor', () {
      // Jan: 0 + 50 + (-20) = 30 (positive); Feb: 30 + 10 + 0 = 40
      final result = computeCategoryAvailableSeries(
        months: [jan, feb],
        assignedFor: (m) => m == jan ? const Money(50000) : const Money(10000),
        activityFor: (m) =>
            m == jan ? const Money(-20000) : const Money.zero(),
        creditOverspentFor: (_) => const Money(99999),
      );

      expect(result[jan], const Money(30000));
      expect(result[feb], const Money(40000)); // positive carryover unchanged
    });

    test('multi-month: mixed carry chains correctly across three months', () {
      // Jan: 0+10+(-30)=-20; creditOverspent=5 → carryover=max(-20,-5)=-5
      // Feb: -5+10+0=5 (positive) → carryover=5
      // Mar: 5+0+0=5
      final result = computeCategoryAvailableSeries(
        months: [jan, feb, mar],
        assignedFor: (m) => m == jan || m == feb
            ? const Money(10000)
            : const Money.zero(),
        activityFor: (m) =>
            m == jan ? const Money(-30000) : const Money.zero(),
        creditOverspentFor: (m) =>
            m == jan ? const Money(5000) : const Money.zero(),
      );

      expect(result[jan], const Money(-20000));
      expect(result[feb], const Money(5000)); // -5 + 10 = 5
      expect(result[mar], const Money(5000));
    });
  });
}
