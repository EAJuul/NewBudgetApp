import 'package:budget_app/data/daos/transactions_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDb() {
  return AppDatabase.forTesting(
    NativeDatabase.memory(
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
}

void main() {
  late AppDatabase db;
  late TransactionsDao dao;

  setUp(() {
    db = _createTestDb();
    dao = TransactionsDao(db);
  });

  tearDown(() => db.close());

  // helper: seed budget + account
  Future<void> seedBudgetAndAccount(String budgetId, String accountId) async {
    await db.into(db.budgets).insert(
          BudgetsCompanion(
            id: Value(budgetId),
            name: const Value('Test Budget'),
            currencyCode: const Value('USD'),
            currencyDecimalDigits: const Value(2),
            dateFormat: const Value('yyyy-MM-dd'),
            createdAt: const Value('2024-01-01T00:00:00Z'),
            updatedAt: const Value('2024-01-01T00:00:00Z'),
          ),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion(
            id: Value(accountId),
            budgetId: Value(budgetId),
            name: const Value('Checking'),
            type: const Value(AccountType.checking),
            onBudget: const Value(true),
            closed: const Value(false),
            sortOrder: const Value(0),
            createdAt: const Value('2024-01-01T00:00:00Z'),
            updatedAt: const Value('2024-01-01T00:00:00Z'),
          ),
        );
  }

  // helper: minimal TransactionsCompanion
  TransactionsCompanion txCompanion({
    required String id,
    required String accountId,
    String date = '2024-03-15',
    int amount = 10000,
    bool deleted = false,
  }) =>
      TransactionsCompanion(
        id: Value(id),
        accountId: Value(accountId),
        date: Value(date),
        amount: Value(amount),
        cleared: const Value(ClearedStatus.uncleared),
        approved: const Value(true),
        isSplit: const Value(false),
        deleted: Value(deleted),
        createdAt: const Value('2024-01-01T00:00:00Z'),
        updatedAt: const Value('2024-01-01T00:00:00Z'),
      );

  test('upsertTransaction then findById returns it', () async {
    await seedBudgetAndAccount('b1', 'a1');
    await dao.upsertTransaction(txCompanion(id: 'tx1', accountId: 'a1'));
    final found = await dao.findById('tx1');
    expect(found != null, isTrue);
    expect(
      found!.id,
      equals('tx1'),
    );
    expect(
      found.amount,
      equals(10000),
    );
  });

  test(
    'watchByAccount emits non-deleted newest-date first and omits other account',
    () async {
      await seedBudgetAndAccount('b1', 'a1');
      // a2's account needs a separate budget? No — accounts can share a budget
      // Re-seed a2 in same budget b1 — but seedBudgetAndAccount inserts budget again which conflicts.
      // Instead insert a2 directly
      await db.into(db.accounts).insert(
            const AccountsCompanion(
              id: Value('a2'),
              budgetId: Value('b1'),
              name: Value('Savings'),
              type: Value(AccountType.checking),
              onBudget: Value(true),
              closed: Value(false),
              sortOrder: Value(1),
              createdAt: Value('2024-01-01T00:00:00Z'),
              updatedAt: Value('2024-01-01T00:00:00Z'),
            ),
          );

      await dao.upsertTransaction(
        txCompanion(id: 'tx1', accountId: 'a1'),
      );
      await dao.upsertTransaction(
        txCompanion(id: 'tx2', accountId: 'a1', date: '2024-03-20'),
      );
      await dao.upsertTransaction(
        txCompanion(id: 'tx3', accountId: 'a1', deleted: true),
      );
      await dao.upsertTransaction(txCompanion(id: 'tx4', accountId: 'a2'));

      final rows = await dao.watchByAccount('a1').first;
      expect(rows.map((r) => r.id).toList(), equals(['tx2', 'tx1']));
    },
  );

  test(
    'softDelete: watchByAccount omits it but findById still returns deleted=true',
    () async {
      await seedBudgetAndAccount('b1', 'a1');
      await dao.upsertTransaction(txCompanion(id: 'tx1', accountId: 'a1'));

      await dao.softDelete('tx1');

      final watched = await dao.watchByAccount('a1').first;
      expect(watched, isEmpty);

      final found = await dao.findById('tx1');
      expect(found != null, isTrue);
      expect(found!.deleted, equals(true));
    },
  );

  test(
    'replaceSubTransactions inserts children; second call replaces them',
    () async {
      await seedBudgetAndAccount('b1', 'a1');
      await dao.upsertTransaction(
        txCompanion(id: 'tx1', accountId: 'a1')
            .copyWith(isSplit: const Value(true)),
      );

      SubTransactionsCompanion subCompanion(String id, int amount) =>
          SubTransactionsCompanion(
            id: Value(id),
            transactionId: const Value('tx1'),
            amount: Value(amount),
            deleted: const Value(false),
          );

      await dao.replaceSubTransactions('tx1', [
        subCompanion('s1', 5000),
        subCompanion('s2', 5000),
      ]);
      var subs = await dao.subTransactionsOf('tx1');
      expect(subs.map((s) => s.id).toList()..sort(), equals(['s1', 's2']));

      // Replace with different set
      await dao.replaceSubTransactions('tx1', [subCompanion('s3', 10000)]);
      subs = await dao.subTransactionsOf('tx1');
      expect(subs.map((s) => s.id).toList(), equals(['s3']));
    },
  );

  test(
    'allForBudget returns transactions from same budget accounts and excludes other budget',
    () async {
      await seedBudgetAndAccount('b1', 'a1');
      // second account in same budget
      await db.into(db.accounts).insert(
            const AccountsCompanion(
              id: Value('a2'),
              budgetId: Value('b1'),
              name: Value('Savings'),
              type: Value(AccountType.checking),
              onBudget: Value(true),
              closed: Value(false),
              sortOrder: Value(1),
              createdAt: Value('2024-01-01T00:00:00Z'),
              updatedAt: Value('2024-01-01T00:00:00Z'),
            ),
          );
      // different budget + account
      await db.into(db.budgets).insert(
            const BudgetsCompanion(
              id: Value('b2'),
              name: Value('Budget 2'),
              currencyCode: Value('USD'),
              currencyDecimalDigits: Value(2),
              dateFormat: Value('yyyy-MM-dd'),
              createdAt: Value('2024-01-01T00:00:00Z'),
              updatedAt: Value('2024-01-01T00:00:00Z'),
            ),
          );
      await db.into(db.accounts).insert(
            const AccountsCompanion(
              id: Value('a3'),
              budgetId: Value('b2'),
              name: Value('Other'),
              type: Value(AccountType.checking),
              onBudget: Value(true),
              closed: Value(false),
              sortOrder: Value(0),
              createdAt: Value('2024-01-01T00:00:00Z'),
              updatedAt: Value('2024-01-01T00:00:00Z'),
            ),
          );

      await dao.upsertTransaction(txCompanion(id: 'tx1', accountId: 'a1'));
      await dao.upsertTransaction(txCompanion(id: 'tx2', accountId: 'a2'));
      await dao.upsertTransaction(txCompanion(id: 'tx3', accountId: 'a3'));

      final rows = await dao.allForBudget('b1');
      final ids = rows.map((r) => r.id).toSet();
      expect(ids, containsAll(['tx1', 'tx2']));
      expect(ids, isNot(contains('tx3')));
    },
  );
}
