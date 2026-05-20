import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';

abstract interface class TransactionRepository {
  Stream<List<Transaction>> watchByAccount(String accountId);
  Future<Transaction?> findById(String id);
  Future<List<SubTransaction>> subTransactionsOf(String transactionId);
  Future<List<Transaction>> allForBudget(String budgetId);
  Future<void> save(
    Transaction transaction, {
    List<SubTransaction> subTransactions = const [],
  });
  Future<void> softDelete(String id);
}
