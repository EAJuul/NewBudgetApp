import 'package:budget_app/core/money/currency_formatter.dart';
import 'package:budget_app/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test(r'zero formats as "$0.00"', () {
      expect(CurrencyFormatter.format(const Money.zero()), r'$0.00');
    });

    test('whole dollar amount', () {
      expect(CurrencyFormatter.format(Money.of(12)), r'$12.00');
    });

    test('sub-unit amount formats both fraction digits', () {
      // $12.34 → 12 units, 340 milliunits
      expect(CurrencyFormatter.format(Money.of(12, 340)), r'$12.34');
    });

    test('groups thousands with commas', () {
      // $1,234.56 → 1234 units, 560 milliunits
      expect(CurrencyFormatter.format(Money.of(1234, 560)), r'$1,234.56');
    });

    test('larger amounts get multiple grouping commas', () {
      // $1,234,567.89
      expect(
        CurrencyFormatter.format(Money.of(1234567, 890)),
        r'$1,234,567.89',
      );
    });

    test('negative amount: leading "-" sits before the symbol', () {
      expect(CurrencyFormatter.format(Money.of(-50)), r'-$50.00');
    });

    test('decimalDigits: 0 omits the fraction and the dot', () {
      expect(
        CurrencyFormatter.format(Money.of(1234), decimalDigits: 0),
        r'$1,234',
      );
    });

    test('custom symbol is used as-is', () {
      expect(CurrencyFormatter.format(Money.of(7, 500), symbol: '€'), '€7.50');
    });

    test('rounds half-up when milliunits do not divide evenly', () {
      // 1235 milliunits = $1.235; with 2 digits rounds to $1.24
      expect(CurrencyFormatter.format(const Money(1235)), r'$1.24');
      // 1234 milliunits rounds to $1.23
      expect(CurrencyFormatter.format(const Money(1234)), r'$1.23');
      // Negative also rounds half-up by magnitude → -$1.24
      expect(CurrencyFormatter.format(const Money(-1235)), r'-$1.24');
    });

    test('three-digit currencies show all three fraction digits', () {
      // 1234560 milliunits at 3 digits → 1,234.560
      expect(
        CurrencyFormatter.format(const Money(1234560), decimalDigits: 3),
        r'$1,234.560',
      );
    });
  });

  group('CurrencyFormatter.tryParse', () {
    test('empty / blank / non-numeric returns null', () {
      expect(CurrencyFormatter.tryParse(''), isNull);
      expect(CurrencyFormatter.tryParse('   '), isNull);
      expect(CurrencyFormatter.tryParse('abc'), isNull);
      expect(CurrencyFormatter.tryParse(r'$'), isNull);
      expect(CurrencyFormatter.tryParse('.'), isNull);
    });

    test('plain integer parses to whole units', () {
      expect(CurrencyFormatter.tryParse('12'), equals(Money.of(12)));
    });

    test('grouped thousands and fraction parses', () {
      expect(
        CurrencyFormatter.tryParse('1,234.56'),
        equals(Money.of(1234, 560)),
      );
    });

    test('leading minus produces negative money', () {
      expect(CurrencyFormatter.tryParse('-50'), equals(Money.of(-50)));
    });

    test('currency symbol after the sign is accepted', () {
      expect(CurrencyFormatter.tryParse(r'-$50'), equals(Money.of(-50)));
    });

    test('currency symbol before the sign is accepted', () {
      expect(CurrencyFormatter.tryParse(r'$-50'), equals(Money.of(-50)));
    });

    test('plain symbol-prefixed amount parses', () {
      expect(CurrencyFormatter.tryParse(r'$12'), equals(Money.of(12)));
    });

    test('surrounding whitespace is ignored', () {
      expect(CurrencyFormatter.tryParse(' 7.5 '), equals(Money.of(7, 500)));
    });

    test('too many fraction digits for decimalDigits returns null', () {
      expect(CurrencyFormatter.tryParse('1.234'), isNull);
      expect(CurrencyFormatter.tryParse('1.2345', decimalDigits: 3), isNull);
    });

    test('two dots returns null', () {
      expect(CurrencyFormatter.tryParse('1.2.3'), isNull);
    });

    test('non-digit body returns null', () {
      expect(CurrencyFormatter.tryParse('12a'), isNull);
      expect(CurrencyFormatter.tryParse('1.2a'), isNull);
    });

    test('decimalDigits: 0 rejects any fraction', () {
      expect(CurrencyFormatter.tryParse('12.3', decimalDigits: 0), isNull);
      expect(
        CurrencyFormatter.tryParse('1,234', decimalDigits: 0),
        equals(Money.of(1234)),
      );
    });

    test('decimalDigits: 3 accepts three fraction digits', () {
      expect(
        CurrencyFormatter.tryParse('1.234', decimalDigits: 3),
        equals(const Money(1234)),
      );
    });

    test('custom symbol is stripped', () {
      expect(
        CurrencyFormatter.tryParse('€7.50', symbol: '€'),
        equals(Money.of(7, 500)),
      );
    });

    test('fraction shorter than decimalDigits pads with zeros', () {
      // "7.5" with 2 digits → 7.50 → 7500 milliunits
      expect(CurrencyFormatter.tryParse('7.5'), equals(const Money(7500)));
    });
  });

  group('CurrencyFormatter round-trip', () {
    test('format → tryParse recovers the original Money', () {
      final samples = <Money>[
        const Money.zero(),
        Money.of(1),
        Money.of(12, 340),
        Money.of(1234, 560),
        Money.of(1234567, 890),
        Money.of(-50),
        Money.of(-1234, -560),
      ];
      for (final m in samples) {
        final formatted = CurrencyFormatter.format(m);
        final parsed = CurrencyFormatter.tryParse(formatted);
        expect(
          parsed,
          equals(m),
          reason: 'round-trip failed for $m → $formatted',
        );
      }
    });

    test('round-trip at decimalDigits: 0', () {
      final m = Money.of(1234);
      final formatted = CurrencyFormatter.format(m, decimalDigits: 0);
      expect(
        CurrencyFormatter.tryParse(formatted, decimalDigits: 0),
        equals(m),
      );
    });

    test('round-trip at decimalDigits: 3', () {
      const m = Money(1234567);
      final formatted = CurrencyFormatter.format(m, decimalDigits: 3);
      expect(
        CurrencyFormatter.tryParse(formatted, decimalDigits: 3),
        equals(m),
      );
    });
  });
}
