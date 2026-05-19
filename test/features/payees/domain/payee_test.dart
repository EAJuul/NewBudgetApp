import 'package:budget_app/features/payees/domain/payee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payee', () {
    test('constructs with all fields', () {
      const payee = Payee(
        id: 'p1',
        budgetId: 'b1',
        name: 'Amazon',
        defaultCategoryId: 'cat1',
      );
      expect(payee.id, 'p1');
      expect(payee.budgetId, 'b1');
      expect(payee.name, 'Amazon');
      expect(payee.defaultCategoryId, 'cat1');
      expect(payee.transferAccountId, isNull);
    });

    test('isTransferPayee is false when transferAccountId is null', () {
      const payee = Payee(id: 'p1', budgetId: 'b1', name: 'Test');
      expect(payee.isTransferPayee, isFalse);
    });

    test('isTransferPayee is true when transferAccountId is non-null', () {
      const payee = Payee(
        id: 'p1',
        budgetId: 'b1',
        name: 'Transfer: Savings',
        transferAccountId: 'a1',
      );
      expect(payee.isTransferPayee, isTrue);
    });

    test('equality and hashCode behave as value object', () {
      const p1 = Payee(id: 'p1', budgetId: 'b1', name: 'Amazon');
      const p2 = Payee(id: 'p1', budgetId: 'b1', name: 'Amazon');
      const p3 = Payee(id: 'p2', budgetId: 'b1', name: 'Amazon');
      expect(p1, equals(p2));
      expect(p1.hashCode, p2.hashCode);
      expect(p1, isNot(equals(p3)));
    });

    test('copyWith updates only specified fields', () {
      const p = Payee(id: 'p1', budgetId: 'b1', name: 'Amazon');
      final updated = p.copyWith(name: 'Google');
      expect(updated.id, 'p1');
      expect(updated.name, 'Google');
    });
  });
}
