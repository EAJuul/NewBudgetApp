import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/scheduled_transactions_table.dart';
import 'package:drift/drift.dart';

part 'scheduled_transactions_dao.g.dart';

@DriftAccessor(tables: [ScheduledTransactions, Accounts])
class ScheduledTransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduledTransactionsDaoMixin {
  ScheduledTransactionsDao(super.attachedDatabase);

  Stream<List<ScheduledTransactionRow>> watchByBudget(String budgetId) {
    final query = select(scheduledTransactions).join([
      innerJoin(
        accounts,
        accounts.id.equalsExp(scheduledTransactions.accountId),
      ),
    ])
      ..where(accounts.budgetId.equals(budgetId));
    return query.map((row) => row.readTable(scheduledTransactions)).watch();
  }

  Future<List<ScheduledTransactionRow>> dueByBudget(
    String budgetId,
    String asOf,
  ) {
    final query = select(scheduledTransactions).join([
      innerJoin(
        accounts,
        accounts.id.equalsExp(scheduledTransactions.accountId),
      ),
    ])
      ..where(
        accounts.budgetId.equals(budgetId) &
            scheduledTransactions.nextDate.isSmallerOrEqualValue(asOf),
      );
    return query.map((row) => row.readTable(scheduledTransactions)).get();
  }

  Future<ScheduledTransactionRow?> findById(String id) =>
      (select(scheduledTransactions)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(ScheduledTransactionsCompanion schedule) =>
      into(scheduledTransactions).insertOnConflictUpdate(schedule);

  Future<void> deleteById(String id) =>
      (delete(scheduledTransactions)..where((s) => s.id.equals(id))).go();
}
