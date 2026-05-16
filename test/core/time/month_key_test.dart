import 'package:budget_app/core/time/month_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthKey construction', () {
    test('stores year and month', () {
      const k = MonthKey(2026, 5);
      expect(k.year, 2026);
      expect(k.month, 5);
    });

    test('asserts month in 1..12', () {
      expect(() => MonthKey(2026, 0), throwsAssertionError);
      expect(() => MonthKey(2026, 13), throwsAssertionError);
      expect(() => const MonthKey(2026, 1), returnsNormally);
      expect(() => const MonthKey(2026, 12), returnsNormally);
    });
  });

  group('MonthKey.fromDate', () {
    test('extracts year and month from date', () {
      expect(
        MonthKey.fromDate(DateTime(2026, 5, 16)),
        equals(const MonthKey(2026, 5)),
      );
    });

    test('first day of month', () {
      expect(
        MonthKey.fromDate(DateTime(2025)),
        equals(const MonthKey(2025, 1)),
      );
    });

    test('last day of month', () {
      expect(
        MonthKey.fromDate(DateTime(2025, 1, 31)),
        equals(const MonthKey(2025, 1)),
      );
    });
  });

  group('MonthKey.parse', () {
    test('parses valid YYYY-MM string', () {
      expect(MonthKey.parse('2026-05'), equals(const MonthKey(2026, 5)));
    });

    test('round-trips with toIso', () {
      const k = MonthKey(2024, 12);
      expect(MonthKey.parse(k.toIso()), equals(k));
    });

    test('rejects month 00', () {
      expect(() => MonthKey.parse('2026-00'), throwsFormatException);
    });

    test('rejects month 13', () {
      expect(() => MonthKey.parse('2026-13'), throwsFormatException);
    });

    test('rejects single-digit month', () {
      expect(() => MonthKey.parse('2026-1'), throwsFormatException);
    });

    test('rejects non-numeric input', () {
      expect(() => MonthKey.parse('abc'), throwsFormatException);
    });

    test('rejects empty string', () {
      expect(() => MonthKey.parse(''), throwsFormatException);
    });

    test('rejects wrong separator', () {
      expect(() => MonthKey.parse('2026/05'), throwsFormatException);
    });
  });

  group('MonthKey.toIso / toString', () {
    test('zero-pads single-digit month', () {
      expect(const MonthKey(2026, 5).toIso(), '2026-05');
    });

    test('two-digit month unchanged', () {
      expect(const MonthKey(2026, 12).toIso(), '2026-12');
    });

    test('toString equals toIso', () {
      const k = MonthKey(2026, 3);
      expect(k.toString(), k.toIso());
    });
  });

  group('MonthKey.next', () {
    test('advances month within a year', () {
      expect(const MonthKey(2026, 5).next(), equals(const MonthKey(2026, 6)));
    });

    test('December rolls to January of the next year', () {
      expect(const MonthKey(2025, 12).next(), equals(const MonthKey(2026, 1)));
    });
  });

  group('MonthKey.previous', () {
    test('goes back within a year', () {
      expect(
        const MonthKey(2026, 5).previous(),
        equals(const MonthKey(2026, 4)),
      );
    });

    test('January rolls to December of the prior year', () {
      expect(
        const MonthKey(2026, 1).previous(),
        equals(const MonthKey(2025, 12)),
      );
    });
  });

  group('MonthKey.addMonths', () {
    test('positive count crosses year boundary', () {
      expect(
        const MonthKey(2025, 11).addMonths(3),
        equals(const MonthKey(2026, 2)),
      );
    });

    test('negative count crosses year boundary backward', () {
      expect(
        const MonthKey(2026, 2).addMonths(-3),
        equals(const MonthKey(2025, 11)),
      );
    });

    test('zero count returns same month', () {
      expect(
        const MonthKey(2026, 5).addMonths(0),
        equals(const MonthKey(2026, 5)),
      );
    });

    test('large positive count', () {
      expect(
        const MonthKey(2024, 1).addMonths(24),
        equals(const MonthKey(2026, 1)),
      );
    });
  });

  group('MonthKey.monthsUntil', () {
    test('positive when other is later', () {
      expect(
        const MonthKey(2026, 1).monthsUntil(const MonthKey(2026, 4)),
        3,
      );
    });

    test('negative when other is earlier', () {
      expect(
        const MonthKey(2026, 4).monthsUntil(const MonthKey(2026, 1)),
        -3,
      );
    });

    test('zero for same month', () {
      expect(
        const MonthKey(2026, 5).monthsUntil(const MonthKey(2026, 5)),
        0,
      );
    });

    test('is the inverse of addMonths', () {
      const base = MonthKey(2025, 6);
      const other = MonthKey(2027, 3);
      final diff = base.monthsUntil(other);
      expect(base.addMonths(diff), equals(other));
    });
  });

  group('MonthKey.contains', () {
    test('first day of month is contained', () {
      expect(
        const MonthKey(2026, 5).contains(DateTime(2026, 5)),
        isTrue,
      );
    });

    test('last day of month is contained', () {
      expect(
        const MonthKey(2026, 5).contains(DateTime(2026, 5, 31)),
        isTrue,
      );
    });

    test('mid-month date is contained', () {
      expect(
        const MonthKey(2026, 5).contains(DateTime(2026, 5, 16)),
        isTrue,
      );
    });

    test('day before month is not contained', () {
      expect(
        const MonthKey(2026, 5).contains(DateTime(2026, 4, 30)),
        isFalse,
      );
    });

    test('day after month is not contained', () {
      expect(
        const MonthKey(2026, 5).contains(DateTime(2026, 6)),
        isFalse,
      );
    });
  });

  group('MonthKey equality and hashCode', () {
    test('equal months are equal', () {
      expect(const MonthKey(2026, 5), equals(const MonthKey(2026, 5)));
    });

    test('different year is not equal', () {
      expect(
        const MonthKey(2025, 5),
        isNot(equals(const MonthKey(2026, 5))),
      );
    });

    test('different month is not equal', () {
      expect(
        const MonthKey(2026, 4),
        isNot(equals(const MonthKey(2026, 5))),
      );
    });

    test('hashCode is consistent', () {
      expect(
        const MonthKey(2026, 5).hashCode,
        equals(const MonthKey(2026, 5).hashCode),
      );
    });

    test('usable as Map key', () {
      final m = {
        const MonthKey(2026, 1): 'jan',
        const MonthKey(2026, 2): 'feb',
      };
      expect(m[const MonthKey(2026, 1)], 'jan');
    });
  });

  group('MonthKey.compareTo', () {
    test('earlier month is less', () {
      expect(
        const MonthKey(2026, 1).compareTo(const MonthKey(2026, 5)),
        isNegative,
      );
    });

    test('later month is greater', () {
      expect(
        const MonthKey(2026, 5).compareTo(const MonthKey(2026, 1)),
        isPositive,
      );
    });

    test('same month returns 0', () {
      expect(
        const MonthKey(2026, 5).compareTo(const MonthKey(2026, 5)),
        0,
      );
    });

    test('sorts a list correctly', () {
      final list = [
        const MonthKey(2026, 3),
        const MonthKey(2025, 12),
        const MonthKey(2026, 1),
      ];
      expect(list..sort(), [
        const MonthKey(2025, 12),
        const MonthKey(2026, 1),
        const MonthKey(2026, 3),
      ]);
    });
  });
}
