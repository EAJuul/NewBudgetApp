import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';

abstract interface class CategoryRepository {
  Stream<List<CategoryGroup>> watchAllGroups(String budgetId);
  Stream<List<Category>> watchCategoriesInGroup(String groupId);
  Future<Category?> findCategoryById(String id);
  Future<void> saveGroup(CategoryGroup group);
  Future<void> saveCategory(Category category);
  Future<void> deleteGroup(String id);
  Future<void> deleteCategory(String id);
}
