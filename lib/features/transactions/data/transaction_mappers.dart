import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:drift/drift.dart';

String _dateToString(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Transaction transactionFromRow(TransactionRow row) => Transaction(
      id: row.id,
      accountId: row.accountId,
      date: DateTime.parse(row.date),
      amount: Money(row.amount),
      cleared: row.cleared,
      approved: row.approved,
      isSplit: row.isSplit,
      deleted: row.deleted,
      payeeId: row.payeeId,
      categoryId: row.categoryId,
      memo: row.memo,
      flagColor: row.flagColor,
      transferTransactionId: row.transferTransactionId,
      transferAccountId: row.transferAccountId,
      scheduledTransactionId: row.scheduledTransactionId,
      importId: row.importId,
    );

TransactionsCompanion transactionToCompanion(
  Transaction transaction, {
  required String createdAt,
  required String updatedAt,
}) =>
    TransactionsCompanion(
      id: Value(transaction.id),
      accountId: Value(transaction.accountId),
      date: Value(_dateToString(transaction.date)),
      amount: Value(transaction.amount.milliunits),
      cleared: Value(transaction.cleared),
      approved: Value(transaction.approved),
      isSplit: Value(transaction.isSplit),
      deleted: Value(transaction.deleted),
      payeeId: Value(transaction.payeeId),
      categoryId: Value(transaction.categoryId),
      memo: Value(transaction.memo),
      flagColor: Value(transaction.flagColor),
      transferTransactionId: Value(transaction.transferTransactionId),
      transferAccountId: Value(transaction.transferAccountId),
      scheduledTransactionId: Value(transaction.scheduledTransactionId),
      importId: Value(transaction.importId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );

SubTransaction subTransactionFromRow(SubTransactionRow row) => SubTransaction(
      id: row.id,
      transactionId: row.transactionId,
      amount: Money(row.amount),
      deleted: row.deleted,
      categoryId: row.categoryId,
      payeeId: row.payeeId,
      memo: row.memo,
    );

SubTransactionsCompanion subTransactionToCompanion(SubTransaction sub) =>
    SubTransactionsCompanion(
      id: Value(sub.id),
      transactionId: Value(sub.transactionId),
      amount: Value(sub.amount.milliunits),
      deleted: Value(sub.deleted),
      categoryId: Value(sub.categoryId),
      payeeId: Value(sub.payeeId),
      memo: Value(sub.memo),
    );
