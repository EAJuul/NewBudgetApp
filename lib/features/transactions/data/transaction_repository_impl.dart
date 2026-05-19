import 'package:budget_app/data/daos/transactions_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/transactions/data/transaction_mappers.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(AppDatabase db)
      : _dao = TransactionsDao(db),
        _db = db;

  final TransactionsDao _dao;
  final AppDatabase _db;

  @override
  Stream<List<Transaction>> watchByAccount(String accountId) => _dao
      .watchByAccount(accountId)
      .map((rows) => rows.map(transactionFromRow).toList());

  @override
  Future<Transaction?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : transactionFromRow(row);
  }

  @override
  Future<List<SubTransaction>> subTransactionsOf(String transactionId) async {
    final rows = await _dao.subTransactionsOf(transactionId);
    return rows.map(subTransactionFromRow).toList();
  }

  @override
  Future<List<Transaction>> allForBudget(String budgetId) async {
    final rows = await _dao.allForBudget(budgetId);
    return rows.map(transactionFromRow).toList();
  }

  @override
  Future<void> save(
    Transaction transaction, {
    List<SubTransaction> subTransactions = const [],
  }) async {
    final existing = await _dao.findById(transaction.id);
    final now = DateTime.now().toUtc().toIso8601String();
    final createdAt = existing?.createdAt ?? now;
    final companion = transactionToCompanion(
      transaction,
      createdAt: createdAt,
      updatedAt: now,
    );

    if (transaction.isSplit) {
      await _db.transaction(() async {
        await _dao.upsertTransaction(companion);
        await _dao.replaceSubTransactions(
          transaction.id,
          subTransactions.map(subTransactionToCompanion).toList(),
        );
      });
    } else {
      await _dao.upsertTransaction(companion);
    }
  }

  @override
  Future<void> softDelete(String id) => _dao.softDelete(id);
}
