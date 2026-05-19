import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/category_budgets_table.dart';
import 'package:drift/drift.dart';

part 'category_budgets_dao.g.dart';

@DriftAccessor(tables: [CategoryBudgets])
class CategoryBudgetsDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryBudgetsDaoMixin {
  CategoryBudgetsDao(super.attachedDatabase);

  Stream<List<CategoryBudgetRow>> watchForCategory(String categoryId) =>
      (select(categoryBudgets)..where((t) => t.categoryId.equals(categoryId)))
          .watch();

  Stream<List<CategoryBudgetRow>> watchForMonth(String month) =>
      (select(categoryBudgets)..where((t) => t.month.equals(month))).watch();

  Future<CategoryBudgetRow?> find(String categoryId, String month) =>
      (select(categoryBudgets)
            ..where(
              (t) => t.categoryId.equals(categoryId) & t.month.equals(month),
            ))
          .getSingleOrNull();

  Future<void> upsert(CategoryBudgetsCompanion budget) =>
      into(categoryBudgets).insertOnConflictUpdate(budget);
}
