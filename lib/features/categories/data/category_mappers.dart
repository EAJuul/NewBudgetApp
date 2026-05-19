import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';
import 'package:drift/drift.dart';

CategoryGroup categoryGroupFromRow(CategoryGroupRow row) => CategoryGroup(
      id: row.id,
      budgetId: row.budgetId,
      name: row.name,
      hidden: row.hidden,
      sortOrder: row.sortOrder,
      systemType: row.systemType,
    );

CategoryGroupsCompanion categoryGroupToCompanion(CategoryGroup group) =>
    CategoryGroupsCompanion(
      id: Value(group.id),
      budgetId: Value(group.budgetId),
      name: Value(group.name),
      hidden: Value(group.hidden),
      sortOrder: Value(group.sortOrder),
      systemType: Value(group.systemType),
    );

Category categoryFromRow(CategoryRow row) => Category(
      id: row.id,
      groupId: row.groupId,
      name: row.name,
      hidden: row.hidden,
      note: row.note,
      sortOrder: row.sortOrder,
      linkedAccountId: row.linkedAccountId,
    );

CategoriesCompanion categoryToCompanion(
  Category category, {
  required String createdAt,
  required String updatedAt,
}) =>
    CategoriesCompanion(
      id: Value(category.id),
      groupId: Value(category.groupId),
      name: Value(category.name),
      hidden: Value(category.hidden),
      note: Value(category.note),
      sortOrder: Value(category.sortOrder),
      linkedAccountId: Value(category.linkedAccountId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
