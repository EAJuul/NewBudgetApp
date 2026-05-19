import 'package:budget_app/domain/budgeting/schedule.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('advance — day-based frequencies', () {
    test('daily adds 1 day', () {
      expect(advance(d(2024, 1, 15), ScheduleFrequency.daily), d(2024, 1, 16));
    });

    test('daily crosses month boundary', () {
      expect(advance(d(2024, 1, 31), ScheduleFrequency.daily), d(2024, 2, 1));
    });

    test('daily crosses year boundary', () {
      expect(
        advance(d(2023, 12, 31), ScheduleFrequency.daily),
        d(2024, 1, 1),
      );
    });

    test('weekly adds 7 days', () {
      expect(advance(d(2024, 3, 10), ScheduleFrequency.weekly), d(2024, 3, 17));
    });

    test('weekly crosses month boundary', () {
      expect(advance(d(2024, 3, 28), ScheduleFrequency.weekly), d(2024, 4, 4));
    });

    test('everyOtherWeek adds 14 days', () {
      expect(
        advance(d(2024, 3, 1), ScheduleFrequency.everyOtherWeek),
        d(2024, 3, 15),
      );
    });

    test('every4Weeks adds 28 days', () {
      expect(
        advance(d(2024, 1, 1), ScheduleFrequency.every4Weeks),
        d(2024, 1, 29),
      );
    });

    test('every4Weeks crosses year boundary', () {
      expect(
        advance(d(2023, 12, 20), ScheduleFrequency.every4Weeks),
        d(2024, 1, 17),
      );
    });
  });

  group('advance — monthly', () {
    test('monthly from Jan 15 → Feb 15', () {
      expect(
        advance(d(2024, 1, 15), ScheduleFrequency.monthly),
        d(2024, 2, 15),
      );
    });

    test('monthly from Dec 15 → Jan 15 next year', () {
      expect(
        advance(d(2023, 12, 15), ScheduleFrequency.monthly),
        d(2024, 1, 15),
      );
    });

    test('monthly from Jan 31 → Feb 28 in common year', () {
      expect(
        advance(d(2023, 1, 31), ScheduleFrequency.monthly),
        d(2023, 2, 28),
      );
    });

    test('monthly from Jan 31 → Feb 29 in leap year (2028)', () {
      expect(
        advance(d(2028, 1, 31), ScheduleFrequency.monthly),
        d(2028, 2, 29),
      );
    });

    test('monthly from Mar 31 → Apr 30 (30-day month clamp)', () {
      expect(
        advance(d(2024, 3, 31), ScheduleFrequency.monthly),
        d(2024, 4, 30),
      );
    });
  });

  group('advance — multi-month frequencies', () {
    test('everyOtherMonth advances 2 months', () {
      expect(
        advance(d(2024, 1, 15), ScheduleFrequency.everyOtherMonth),
        d(2024, 3, 15),
      );
    });

    test('everyOtherMonth clamps day (Jan 31 → Mar 31)', () {
      expect(
        advance(d(2024, 1, 31), ScheduleFrequency.everyOtherMonth),
        d(2024, 3, 31),
      );
    });

    test('every3Months advances 3 months', () {
      expect(
        advance(d(2024, 1, 15), ScheduleFrequency.every3Months),
        d(2024, 4, 15),
      );
    });

    test('every3Months crosses year boundary (Nov → Feb)', () {
      expect(
        advance(d(2023, 11, 30), ScheduleFrequency.every3Months),
        d(2024, 2, 29), // 2024 is a leap year
      );
    });

    test('every6Months advances 6 months', () {
      expect(
        advance(d(2024, 1, 31), ScheduleFrequency.every6Months),
        d(2024, 7, 31),
      );
    });

    test('every6Months crosses year boundary', () {
      expect(
        advance(d(2023, 8, 31), ScheduleFrequency.every6Months),
        d(2024, 2, 29), // 2024 leap year
      );
    });

    test('yearly from Feb 28 → Feb 28 in common year', () {
      expect(
        advance(d(2023, 2, 28), ScheduleFrequency.yearly),
        d(2024, 2, 28),
      );
    });

    test('yearly from Feb 29 2028 → Feb 28 2029', () {
      expect(
        advance(d(2028, 2, 29), ScheduleFrequency.yearly),
        d(2029, 2, 28),
      );
    });

    test('yearly from Dec 31 → Dec 31 next year', () {
      expect(
        advance(d(2023, 12, 31), ScheduleFrequency.yearly),
        d(2024, 12, 31),
      );
    });
  });

  group('advance — twiceAMonth', () {
    test('from day 5 (< 15) → 15th of same month', () {
      expect(
        advance(d(2024, 3, 5), ScheduleFrequency.twiceAMonth),
        d(2024, 3, 15),
      );
    });

    test('from day 1 → 15th of same month', () {
      expect(
        advance(d(2024, 3, 1), ScheduleFrequency.twiceAMonth),
        d(2024, 3, 15),
      );
    });

    test('from day 14 (< 15) → 15th of same month', () {
      expect(
        advance(d(2024, 3, 14), ScheduleFrequency.twiceAMonth),
        d(2024, 3, 15),
      );
    });

    test('from day 20 (>= 15) → 1st of next month', () {
      expect(
        advance(d(2024, 3, 20), ScheduleFrequency.twiceAMonth),
        d(2024, 4, 1),
      );
    });

    test('from day 15 (>= 15) → 1st of next month', () {
      expect(
        advance(d(2024, 3, 15), ScheduleFrequency.twiceAMonth),
        d(2024, 4, 1),
      );
    });

    test('from Dec 20 → Jan 1 next year', () {
      expect(
        advance(d(2023, 12, 20), ScheduleFrequency.twiceAMonth),
        d(2024, 1, 1),
      );
    });
  });

  group('advance — time component', () {
    test('returned DateTime has zero time component', () {
      final result = advance(
        DateTime(2024, 3, 15, 14, 30, 45),
        ScheduleFrequency.daily,
      );
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
      expect(result.millisecond, 0);
    });
  });
}
