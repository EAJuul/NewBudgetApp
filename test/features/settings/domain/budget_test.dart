import 'package:budget_app/features/settings/domain/budget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget', () {
    test('constructs with all fields', () {
      const budget = Budget(
        id: 'b1',
        name: 'My Budget',
        currencyCode: 'USD',
        currencyDecimalDigits: 2,
        dateFormat: 'MM/dd/yyyy',
      );
      expect(budget.id, 'b1');
      expect(budget.name, 'My Budget');
      expect(budget.currencyCode, 'USD');
      expect(budget.currencyDecimalDigits, 2);
      expect(budget.dateFormat, 'MM/dd/yyyy');
    });

    test('equality and hashCode as value object', () {
      const b1 = Budget(
        id: 'b1',
        name: 'My Budget',
        currencyCode: 'USD',
        currencyDecimalDigits: 2,
        dateFormat: 'MM/dd/yyyy',
      );
      const b2 = Budget(
        id: 'b1',
        name: 'My Budget',
        currencyCode: 'USD',
        currencyDecimalDigits: 2,
        dateFormat: 'MM/dd/yyyy',
      );
      expect(b1, equals(b2));
      expect(b1.hashCode, b2.hashCode);
    });

    test('copyWith updates only specified fields', () {
      const b = Budget(
        id: 'b1',
        name: 'My Budget',
        currencyCode: 'USD',
        currencyDecimalDigits: 2,
        dateFormat: 'MM/dd/yyyy',
      );
      final updated = b.copyWith(name: 'Updated Budget');
      expect(updated.id, 'b1');
      expect(updated.name, 'Updated Budget');
      expect(updated.currencyCode, 'USD');
    });
  });
}
