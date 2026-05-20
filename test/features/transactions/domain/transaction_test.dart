import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction', () {
    test('constructs with all fields', () {
      final testDate = DateTime(2026, 5, 19);
      const amount = Money(100000);

      final transaction = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        date: testDate,
        amount: amount,
        payeeId: 'payee-1',
        categoryId: 'cat-1',
        memo: 'Test memo',
        cleared: ClearedStatus.cleared,
        approved: true,
        flagColor: FlagColor.red,
        transferTransactionId: 'txn-2',
        transferAccountId: 'acc-2',
        scheduledTransactionId: 'sched-1',
        importId: 'import-1',
        isSplit: false,
        deleted: false,
      );

      expect(transaction.id, 'txn-1');
      expect(transaction.accountId, 'acc-1');
      expect(transaction.date, testDate);
      expect(transaction.amount, amount);
      expect(transaction.payeeId, 'payee-1');
      expect(transaction.categoryId, 'cat-1');
      expect(transaction.memo, 'Test memo');
      expect(transaction.cleared, ClearedStatus.cleared);
      expect(transaction.approved, true);
      expect(transaction.flagColor, FlagColor.red);
      expect(transaction.transferTransactionId, 'txn-2');
      expect(transaction.transferAccountId, 'acc-2');
      expect(transaction.scheduledTransactionId, 'sched-1');
      expect(transaction.importId, 'import-1');
      expect(transaction.isSplit, false);
      expect(transaction.deleted, false);
    });

    test('isTransfer is false when transferTransactionId is null', () {
      final transaction = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        date: DateTime(2026, 5, 19),
        amount: const Money(100000),
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
      );

      expect(transaction.isTransfer, false);
    });

    test('isTransfer is true when transferTransactionId is non-null', () {
      final transaction = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        date: DateTime(2026, 5, 19),
        amount: const Money(100000),
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
        transferTransactionId: 'txn-2',
      );

      expect(transaction.isTransfer, true);
    });

    test('copyWith updates only specified fields', () {
      final original = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        date: DateTime(2026, 5, 19),
        amount: const Money(100000),
        payeeId: 'payee-1',
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
      );

      final updated = original.copyWith(cleared: ClearedStatus.reconciled);

      expect(updated.cleared, ClearedStatus.reconciled);
      expect(updated.id, original.id);
      expect(updated.accountId, original.accountId);
      expect(updated.date, original.date);
      expect(updated.amount, original.amount);
      expect(updated.payeeId, original.payeeId);
      expect(updated.approved, original.approved);
      expect(updated.isSplit, original.isSplit);
      expect(updated.deleted, original.deleted);
    });

    test('equality and hashCode', () {
      final testDate = DateTime(2026, 5, 19);
      const amount = Money(100000);

      final txn1 = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        date: testDate,
        amount: amount,
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
      );

      final txn2 = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        date: testDate,
        amount: amount,
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
      );

      final txn3 = Transaction(
        id: 'txn-2',
        accountId: 'acc-1',
        date: testDate,
        amount: amount,
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
      );

      expect(txn1, txn2);
      expect(txn1.hashCode, txn2.hashCode);
      expect(txn1, isNot(txn3));
    });
  });
}
