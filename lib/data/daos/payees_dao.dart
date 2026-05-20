import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:drift/drift.dart';

part 'payees_dao.g.dart';

@DriftAccessor(tables: [Payees])
class PayeesDao extends DatabaseAccessor<AppDatabase> with _$PayeesDaoMixin {
  PayeesDao(super.attachedDatabase);

  Stream<List<PayeeRow>> watchByBudget(String budgetId) => (select(payees)
        ..where((p) => p.budgetId.equals(budgetId))
        ..orderBy([(p) => OrderingTerm(expression: p.name)]))
      .watch();

  Future<PayeeRow?> findById(String id) =>
      (select(payees)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> upsert(PayeesCompanion payee) =>
      into(payees).insertOnConflictUpdate(payee);

  Future<void> deleteById(String id) =>
      (delete(payees)..where((p) => p.id.equals(id))).go();
}
