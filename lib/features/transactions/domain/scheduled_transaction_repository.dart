import 'package:budget_app/features/transactions/domain/scheduled_transaction.dart';

abstract interface class ScheduledTransactionRepository {
  Stream<List<ScheduledTransaction>> watchAll(String budgetId);
  Future<List<ScheduledTransaction>> due(String budgetId, DateTime asOf);
  Future<ScheduledTransaction?> findById(String id);
  Future<void> save(ScheduledTransaction schedule);
  Future<void> delete(String id);
}
