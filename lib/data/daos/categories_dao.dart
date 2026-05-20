import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/category_groups_table.dart';
import 'package:drift/drift.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoryGroups, Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Stream<List<CategoryGroupRow>> watchGroupsByBudget(String budgetId) =>
      (select(categoryGroups)
            ..where((t) => t.budgetId.equals(budgetId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .watch();

  Stream<List<CategoryRow>> watchCategoriesInGroup(String groupId) =>
      (select(categories)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .watch();

  Future<CategoryRow?> findCategoryById(String id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertGroup(CategoryGroupsCompanion group) =>
      into(categoryGroups).insertOnConflictUpdate(group);

  Future<void> upsertCategory(CategoriesCompanion category) =>
      into(categories).insertOnConflictUpdate(category);

  Future<void> deleteGroup(String id) =>
      (delete(categoryGroups)..where((t) => t.id.equals(id))).go();

  Future<void> deleteCategory(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();
}
