import 'package:budget_app/data/daos/scheduled_transactions_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/transactions/data/scheduled_transaction_mappers.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction_repository.dart';

class ScheduledTransactionRepositoryImpl
    implements ScheduledTransactionRepository {
  ScheduledTransactionRepositoryImpl(AppDatabase db)
      : _dao = ScheduledTransactionsDao(db);

  final ScheduledTransactionsDao _dao;

  @override
  Stream<List<ScheduledTransaction>> watchAll(String budgetId) => _dao
      .watchByBudget(budgetId)
      .map((rows) => rows.map(scheduledTransactionFromRow).toList());

  @override
  Future<List<ScheduledTransaction>> due(String budgetId, DateTime asOf) async {
    final dateStr =
        '${asOf.year}-${asOf.month.toString().padLeft(2, '0')}-${asOf.day.toString().padLeft(2, '0')}';
    final rows = await _dao.dueByBudget(budgetId, dateStr);
    return rows.map(scheduledTransactionFromRow).toList();
  }

  @override
  Future<ScheduledTransaction?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : scheduledTransactionFromRow(row);
  }

  @override
  Future<void> save(ScheduledTransaction schedule) async {
    final existing = await _dao.findById(schedule.id);
    final now = DateTime.now().toUtc().toIso8601String();
    final createdAt = existing?.createdAt ?? now;
    await _dao.upsert(
      scheduledTransactionToCompanion(
        schedule,
        createdAt: createdAt,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}
