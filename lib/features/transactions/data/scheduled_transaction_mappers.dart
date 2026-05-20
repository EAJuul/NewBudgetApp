import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction.dart';
import 'package:drift/drift.dart';

String _dateToString(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

ScheduledTransaction scheduledTransactionFromRow(ScheduledTransactionRow row) =>
    ScheduledTransaction(
      id: row.id,
      accountId: row.accountId,
      amount: Money(row.amount),
      payeeId: row.payeeId,
      categoryId: row.categoryId,
      memo: row.memo,
      frequency: row.frequency,
      nextDate: DateTime.parse(row.nextDate),
    );

ScheduledTransactionsCompanion scheduledTransactionToCompanion(
  ScheduledTransaction schedule, {
  required String createdAt,
  required String updatedAt,
}) =>
    ScheduledTransactionsCompanion(
      id: Value(schedule.id),
      accountId: Value(schedule.accountId),
      amount: Value(schedule.amount.milliunits),
      payeeId: Value(schedule.payeeId),
      categoryId: Value(schedule.categoryId),
      memo: Value(schedule.memo),
      frequency: Value(schedule.frequency),
      nextDate: Value(_dateToString(schedule.nextDate)),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
