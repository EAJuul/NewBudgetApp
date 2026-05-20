import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/sub_transactions_table.dart';
import 'package:budget_app/data/database/tables/transactions_table.dart';
import 'package:drift/drift.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions, SubTransactions, Accounts])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  /// Non-deleted transactions for [accountId], `date` descending.
  Stream<List<TransactionRow>> watchByAccount(String accountId) => (select(
        transactions,
      )
            ..where(
              (t) => t.accountId.equals(accountId) & t.deleted.equals(false),
            )
            ..orderBy(
              [
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ],
            ))
          .watch();

  Future<TransactionRow?> findById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Non-deleted sub-transactions of [transactionId].
  Future<List<SubTransactionRow>> subTransactionsOf(String transactionId) =>
      (select(subTransactions)
            ..where(
              (s) =>
                  s.transactionId.equals(transactionId) &
                  s.deleted.equals(false),
            ))
          .get();

  /// Non-deleted transactions for every account in [budgetId]
  /// (joins `transactions` → `accounts`).
  Future<List<TransactionRow>> allForBudget(String budgetId) {
    final query = select(transactions).join([
      innerJoin(accounts, accounts.id.equalsExp(transactions.accountId)),
    ])
      ..where(
        transactions.deleted.equals(false) & accounts.budgetId.equals(budgetId),
      );
    return query.map((row) => row.readTable(transactions)).get();
  }

  Future<void> upsertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insertOnConflictUpdate(transaction);

  /// Atomically replace the sub-transactions of [parentId] with [subs].
  Future<void> replaceSubTransactions(
    String parentId,
    List<SubTransactionsCompanion> subs,
  ) =>
      transaction(() async {
        await (delete(subTransactions)
              ..where((s) => s.transactionId.equals(parentId)))
            .go();
        for (final sub in subs) {
          await into(subTransactions).insertOnConflictUpdate(sub);
        }
      });

  /// Soft delete — sets `deleted = true` on the transaction.
  Future<void> softDelete(String id) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(deleted: Value(true)));
}
