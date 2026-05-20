import 'package:budget_app/data/daos/categories_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/categories/data/category_mappers.dart';
import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';
import 'package:budget_app/features/categories/domain/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(AppDatabase db) : _dao = CategoriesDao(db);

  final CategoriesDao _dao;

  @override
  Stream<List<CategoryGroup>> watchAllGroups(String budgetId) =>
      _dao.watchGroupsByBudget(budgetId).map(
            (rows) => rows.map(categoryGroupFromRow).toList(),
          );

  @override
  Stream<List<Category>> watchCategoriesInGroup(String groupId) =>
      _dao.watchCategoriesInGroup(groupId).map(
            (rows) => rows.map(categoryFromRow).toList(),
          );

  @override
  Future<Category?> findCategoryById(String id) async {
    final row = await _dao.findCategoryById(id);
    return row == null ? null : categoryFromRow(row);
  }

  @override
  Future<void> saveGroup(CategoryGroup group) =>
      _dao.upsertGroup(categoryGroupToCompanion(group));

  @override
  Future<void> saveCategory(Category category) async {
    final existing = await _dao.findCategoryById(category.id);
    final now = DateTime.now().toUtc().toIso8601String();
    final createdAt = existing?.createdAt ?? now;
    await _dao.upsertCategory(
      categoryToCompanion(category, createdAt: createdAt, updatedAt: now),
    );
  }

  @override
  Future<void> deleteGroup(String id) => _dao.deleteGroup(id);

  @override
  Future<void> deleteCategory(String id) => _dao.deleteCategory(id);
}
