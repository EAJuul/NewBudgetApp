import 'package:budget_app/data/database/tables/sub_transactions_table.dart';
import 'package:budget_app/data/database/tables/transactions_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

part 'transactions_test.g.dart';

@DriftDatabase(tables: [Transactions, SubTransactions])
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

void main() {
  const uuid = Uuid();
  const timestamp = '2026-05-16T12:00:00Z';

  group('Transactions and SubTransactions tables', () {
    late _TestDb db;
    const accountId = 'account-1';

    setUp(() => db = _TestDb());

    tearDown(() => db.close());

    test('negative amount with uncleared status and null flagColor round-trip',
        () async {
      final txnId = uuid.v4();
      const amount = -5000; // negative milliunits

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              id: txnId,
              accountId: accountId,
              date: '2026-05-16',
              amount: amount,
              cleared: ClearedStatus.uncleared,
              approved: true,
              isSplit: false,
              deleted: false,
              createdAt: timestamp,
              updatedAt: timestamp,
              flagColor: const Value(null),
            ),
          );

      final row = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txnId)))
          .getSingle();

      expect(row.amount, amount);
      expect(row.cleared, ClearedStatus.uncleared);
      expect(row.flagColor, null);
    });

    test('cleared and flagColor enum columns round-trip', () async {
      final txnId = uuid.v4();

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              id: txnId,
              accountId: accountId,
              date: '2026-05-16',
              amount: 10000,
              cleared: ClearedStatus.reconciled,
              approved: true,
              isSplit: false,
              deleted: false,
              createdAt: timestamp,
              updatedAt: timestamp,
              flagColor: const Value(FlagColor.red),
            ),
          );

      final row = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txnId)))
          .getSingle();

      expect(row.cleared, ClearedStatus.reconciled);
      expect(row.flagColor, FlagColor.red);
    });

    test('isSplit transaction with SubTransactions rows', () async {
      final txnId = uuid.v4();

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              id: txnId,
              accountId: accountId,
              date: '2026-05-16',
              amount: 15000,
              cleared: ClearedStatus.uncleared,
              approved: true,
              isSplit: true,
              deleted: false,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      final subTxn1Id = uuid.v4();
      final subTxn2Id = uuid.v4();

      await db.into(db.subTransactions).insert(
            SubTransactionsCompanion.insert(
              id: subTxn1Id,
              transactionId: txnId,
              amount: 8000,
              deleted: false,
            ),
          );

      await db.into(db.subTransactions).insert(
            SubTransactionsCompanion.insert(
              id: subTxn2Id,
              transactionId: txnId,
              amount: 7000,
              deleted: false,
            ),
          );

      final subRows = await (db.select(db.subTransactions)
            ..where((t) => t.transactionId.equals(txnId)))
          .get();

      expect(subRows.length, 2);
      expect(subRows[0].amount, 8000);
      expect(subRows[1].amount, 7000);
    });

    test('deleted flag round-trips', () async {
      final txnId = uuid.v4();

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              id: txnId,
              accountId: accountId,
              date: '2026-05-16',
              amount: 5000,
              cleared: ClearedStatus.uncleared,
              approved: true,
              isSplit: false,
              deleted: true,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      final row = await (db.select(db.transactions)
            ..where((t) => t.id.equals(txnId)))
          .getSingle();

      expect(row.deleted, isTrue);
    });

    test('SubTransactions with non-existent transactionId', () async {
      final subTxnId = uuid.v4();
      const nonExistentTxnId = 'does-not-exist';

      // Verify that we can attempt to insert a SubTransaction with a non-existent
      // transactionId. Foreign key enforcement is database-dependent.
      // This test ensures the column structure accepts text values.
      final result = await db.into(db.subTransactions).insert(
            SubTransactionsCompanion.insert(
              id: subTxnId,
              transactionId: nonExistentTxnId,
              amount: 5000,
              deleted: false,
            ),
          );

      expect(result, greaterThan(0));
    });
  });
}
