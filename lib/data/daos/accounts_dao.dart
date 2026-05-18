import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:drift/drift.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.attachedDatabase);

  Stream<List<Account>> watchByBudget(String budgetId) => (select(accounts)
        ..where((t) => t.budgetId.equals(budgetId))
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
      .watch();

  Future<Account?> findById(String id) =>
      (select(accounts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(AccountsCompanion account) =>
      into(accounts).insertOnConflictUpdate(account);

  Future<void> deleteById(String id) =>
      (delete(accounts)..where((t) => t.id.equals(id))).go();
}
