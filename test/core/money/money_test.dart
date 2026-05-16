import 'package:budget_app/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money construction', () {
    test('Money(12340) equals Money.of(12, 340)', () {
      expect(const Money(12340), equals(Money.of(12, 340)));
    });

    test('Money.of with default milliunits', () {
      expect(Money.of(5), equals(const Money(5000)));
    });

    test('Money.zero() has milliunits == 0', () {
      expect(const Money.zero().milliunits, 0);
    });

    test('Money.of negative units', () {
      expect(Money.of(-3, -500), equals(const Money(-3500)));
    });
  });

  group('Money predicates', () {
    test('zero is isZero', () {
      expect(const Money.zero().isZero, isTrue);
      expect(const Money.zero().isPositive, isFalse);
      expect(const Money.zero().isNegative, isFalse);
    });

    test('positive amount', () {
      expect(const Money(1).isPositive, isTrue);
      expect(const Money(1).isNegative, isFalse);
      expect(const Money(1).isZero, isFalse);
    });

    test('negative amount', () {
      expect(const Money(-1).isNegative, isTrue);
      expect(const Money(-1).isPositive, isFalse);
      expect(const Money(-1).isZero, isFalse);
    });
  });

  group('Money arithmetic', () {
    test('addition', () {
      expect(const Money(500) + const Money(250), equals(const Money(750)));
    });

    test('subtraction to negative result', () {
      expect(const Money(100) - const Money(300), equals(const Money(-200)));
    });

    test('unary negate', () {
      expect(-const Money(400), equals(const Money(-400)));
      expect(-const Money(-400), equals(const Money(400)));
      expect(-const Money.zero(), equals(const Money.zero()));
    });

    test('multiply by positive factor', () {
      expect(const Money(100) * 3, equals(const Money(300)));
    });

    test('multiply by zero', () {
      expect(const Money(500) * 0, equals(const Money.zero()));
    });

    test('multiply by negative factor', () {
      expect(const Money(200) * -2, equals(const Money(-400)));
    });
  });

  group('Money comparison operators', () {
    test('less than', () {
      expect(const Money(100) < const Money(200), isTrue);
      expect(const Money(200) < const Money(100), isFalse);
    });

    test('less than or equal', () {
      expect(const Money(100) <= const Money(100), isTrue);
      expect(const Money(100) <= const Money(200), isTrue);
      expect(const Money(200) <= const Money(100), isFalse);
    });

    test('greater than', () {
      expect(const Money(200) > const Money(100), isTrue);
      expect(const Money(100) > const Money(200), isFalse);
    });

    test('greater than or equal', () {
      expect(const Money(100) >= const Money(100), isTrue);
      expect(const Money(200) >= const Money(100), isTrue);
      expect(const Money(100) >= const Money(200), isFalse);
    });

    test('equal operands return false for strict comparisons', () {
      expect(const Money(50) < const Money(50), isFalse);
      expect(const Money(50) > const Money(50), isFalse);
    });
  });

  group('Money abs()', () {
    test('abs of negative', () {
      expect(const Money(-500).abs(), equals(const Money(500)));
    });

    test('abs of positive', () {
      expect(const Money(500).abs(), equals(const Money(500)));
    });

    test('abs of zero', () {
      expect(const Money.zero().abs(), equals(const Money.zero()));
    });
  });

  group('Money equality and hashCode', () {
    test('equal values are equal', () {
      expect(const Money(1000), equals(const Money(1000)));
    });

    test('different values are not equal', () {
      expect(const Money(1000), isNot(equals(const Money(999))));
    });

    test('hashCode is consistent', () {
      expect(const Money(1000).hashCode, equals(const Money(1000).hashCode));
    });

    test('usable as Set key', () {
      final s = <Money>{}
        ..add(const Money(100))
        ..add(const Money(200))
        ..add(const Money(100));
      expect(s.length, 2);
    });

    test('usable as Map key', () {
      final m = {const Money(100): 'a', const Money(200): 'b'};
      expect(m[const Money(100)], 'a');
    });
  });

  group('Money compareTo', () {
    test('sorts a list correctly', () {
      final list = [
        const Money(300),
        const Money(100),
        const Money(-50),
        const Money(200),
      ];
      expect(list..sort(), [
        const Money(-50),
        const Money(100),
        const Money(200),
        const Money(300),
      ]);
    });

    test('compareTo equal returns 0', () {
      expect(const Money(100).compareTo(const Money(100)), 0);
    });
  });

  group('Money toString', () {
    test('debug form', () {
      expect(const Money(12340).toString(), 'Money(12340)');
    });
  });
}
