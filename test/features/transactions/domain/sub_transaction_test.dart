import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubTransaction', () {
    test('constructs with all fields', () {
      const amount = Money(50000);

      const subTransaction = SubTransaction(
        id: 'subtxn-1',
        transactionId: 'txn-1',
        amount: amount,
        categoryId: 'cat-1',
        payeeId: 'payee-1',
        memo: 'Sub memo',
        deleted: false,
      );

      expect(subTransaction.id, 'subtxn-1');
      expect(subTransaction.transactionId, 'txn-1');
      expect(subTransaction.amount, amount);
      expect(subTransaction.categoryId, 'cat-1');
      expect(subTransaction.payeeId, 'payee-1');
      expect(subTransaction.memo, 'Sub memo');
      expect(subTransaction.deleted, false);
    });

    test('constructs with nullable fields as null', () {
      const amount = Money(50000);

      const subTransaction = SubTransaction(
        id: 'subtxn-1',
        transactionId: 'txn-1',
        amount: amount,
        deleted: false,
      );

      expect(subTransaction.categoryId, isNull);
      expect(subTransaction.payeeId, isNull);
      expect(subTransaction.memo, isNull);
    });

    test('copyWith updates only specified fields', () {
      const original = SubTransaction(
        id: 'subtxn-1',
        transactionId: 'txn-1',
        amount: Money(50000),
        deleted: false,
      );

      final updated = original.copyWith(deleted: true);

      expect(updated.deleted, true);
      expect(updated.id, original.id);
      expect(updated.transactionId, original.transactionId);
      expect(updated.amount, original.amount);
    });

    test('equality and hashCode', () {
      const amount = Money(50000);

      const subtxn1 = SubTransaction(
        id: 'subtxn-1',
        transactionId: 'txn-1',
        amount: amount,
        deleted: false,
      );

      const subtxn2 = SubTransaction(
        id: 'subtxn-1',
        transactionId: 'txn-1',
        amount: amount,
        deleted: false,
      );

      const subtxn3 = SubTransaction(
        id: 'subtxn-2',
        transactionId: 'txn-1',
        amount: amount,
        deleted: false,
      );

      expect(subtxn1, subtxn2);
      expect(subtxn1.hashCode, subtxn2.hashCode);
      expect(subtxn1, isNot(subtxn3));
    });
  });
}
