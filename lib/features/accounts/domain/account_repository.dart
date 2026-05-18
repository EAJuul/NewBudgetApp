import 'package:budget_app/features/accounts/domain/account.dart';

abstract interface class AccountRepository {
  /// Emits the full list whenever any account in [budgetId] changes.
  Stream<List<Account>> watchAll(String budgetId);
  Future<Account?> findById(String id);

  /// Insert or update by [Account.id] (upsert semantics).
  Future<void> save(Account account);
  Future<void> delete(String id);
}
