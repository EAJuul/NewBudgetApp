import 'package:budget_app/data/daos/accounts_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/accounts/data/account_mappers.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:budget_app/features/accounts/domain/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(AppDatabase db) : _dao = AccountsDao(db);

  final AccountsDao _dao;

  @override
  Stream<List<Account>> watchAll(String budgetId) => _dao
      .watchByBudget(budgetId)
      .map((rows) => rows.map(accountFromRow).toList());

  @override
  Future<Account?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : accountFromRow(row);
  }

  @override
  Future<void> save(Account account) async {
    final existing = await _dao.findById(account.id);
    final now = DateTime.now().toUtc().toIso8601String();
    final createdAt = existing?.createdAt ?? now;
    await _dao.upsert(
      accountToCompanion(account, createdAt: createdAt, updatedAt: now),
    );
  }

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}
