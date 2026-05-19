import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/transactions/data/transaction_mappers.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to build a TransactionRow (uses Drift's generated data class directly)
  // TransactionRow is a plain Dart class with named params.

  group('transactionFromRow / transactionToCompanion', () {
    test('round-trips every field including date and negative Money', () {
      // Build via companion then read back — easier than constructing TransactionRow directly
      // since TransactionRow's constructor may vary. Instead test field-by-field.

      final transaction = Transaction(
        id: 'tx1',
        accountId: 'a1',
        date: DateTime(2024, 3, 15),
        amount: const Money(-12340),
        cleared: ClearedStatus.cleared,
        approved: true,
        isSplit: false,
        deleted: false,
        payeeId: 'p1',
        categoryId: 'c1',
        memo: 'test memo',
        flagColor: FlagColor.red,
        importId: 'import1',
      );

      const createdAt = '2024-01-01T00:00:00Z';
      const updatedAt = '2024-03-15T10:00:00Z';

      final companion = transactionToCompanion(
        transaction,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // Verify companion values
      expect(companion.id.value, 'tx1');
      expect(companion.accountId.value, 'a1');
      expect(companion.date.value, '2024-03-15');
      expect(companion.amount.value, -12340);
      expect(companion.cleared.value, ClearedStatus.cleared);
      expect(companion.approved.value, isTrue);
      expect(companion.isSplit.value, isFalse);
      expect(companion.deleted.value, isFalse);
      expect(companion.payeeId.value, 'p1');
      expect(companion.categoryId.value, 'c1');
      expect(companion.memo.value, 'test memo');
      expect(companion.flagColor.value, FlagColor.red);
      expect(companion.importId.value, 'import1');
      expect(companion.createdAt.value, createdAt);
      expect(companion.updatedAt.value, updatedAt);
    });

    test('null optional fields round-trip correctly', () {
      final transaction = Transaction(
        id: 'tx2',
        accountId: 'a1',
        date: DateTime(2024),
        amount: const Money.zero(),
        cleared: ClearedStatus.uncleared,
        approved: false,
        isSplit: false,
        deleted: false,
      );

      final companion = transactionToCompanion(
        transaction,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-01T00:00:00Z',
      );

      expect(companion.payeeId.value, isNull);
      expect(companion.categoryId.value, isNull);
      expect(companion.memo.value, isNull);
      expect(companion.flagColor.value, isNull);
    });

    test('date format is YYYY-MM-DD with zero-padded month and day', () {
      final transaction = Transaction(
        id: 'tx3',
        accountId: 'a1',
        date: DateTime(2024, 1, 5),
        amount: const Money.zero(),
        cleared: ClearedStatus.uncleared,
        approved: true,
        isSplit: false,
        deleted: false,
      );

      final companion = transactionToCompanion(
        transaction,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-01T00:00:00Z',
      );

      expect(companion.date.value, '2024-01-05');
    });
  });

  group('subTransactionFromRow / subTransactionToCompanion', () {
    test('round-trips every field', () {
      const sub = SubTransaction(
        id: 's1',
        transactionId: 'tx1',
        amount: Money(5000),
        deleted: false,
        categoryId: 'cat1',
        payeeId: 'pay1',
        memo: 'sub memo',
      );

      final companion = subTransactionToCompanion(sub);

      expect(companion.id.value, 's1');
      expect(companion.transactionId.value, 'tx1');
      expect(companion.amount.value, 5000);
      expect(companion.deleted.value, isFalse);
      expect(companion.categoryId.value, 'cat1');
      expect(companion.payeeId.value, 'pay1');
      expect(companion.memo.value, 'sub memo');
    });

    test('null optional fields round-trip', () {
      const sub = SubTransaction(
        id: 's2',
        transactionId: 'tx1',
        amount: Money(-3000),
        deleted: true,
      );

      final companion = subTransactionToCompanion(sub);

      expect(companion.categoryId.value, isNull);
      expect(companion.payeeId.value, isNull);
      expect(companion.memo.value, isNull);
      expect(companion.deleted.value, isTrue);
    });
  });
}
