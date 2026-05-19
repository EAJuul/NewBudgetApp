import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/budgets_table.dart';
import 'package:drift/drift.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.attachedDatabase);

  Future<BudgetRow?> findFirst() =>
      (select(budgets)..limit(1)).getSingleOrNull();

  Stream<BudgetRow?> watchFirst() =>
      (select(budgets)..limit(1)).watchSingleOrNull();

  Future<void> upsert(BudgetsCompanion budget) =>
      into(budgets).insertOnConflictUpdate(budget);
}
