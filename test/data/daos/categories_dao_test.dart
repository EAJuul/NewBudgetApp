import 'package:budget_app/data/daos/categories_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoriesDao', () {
    late AppDatabase db;
    late CategoriesDao dao;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = CategoriesDao(db);
    });

    tearDown(() => db.close());

    test('watchGroupsByBudget emits group from matching budget only', () async {
      // Seed budget 1
      const budgetId1 = 'budget-1';
      const budgetId2 = 'budget-2';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId1,
              name: 'Budget 1',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId2,
              name: 'Budget 2',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );

      // Seed groups
      const group1Id = 'group-1';
      const group2Id = 'group-2';
      await dao.upsertGroup(
        CategoryGroupsCompanion.insert(
          id: group1Id,
          budgetId: budgetId1,
          name: 'Group 1',
          hidden: false,
          sortOrder: 1,
        ),
      );
      await dao.upsertGroup(
        CategoryGroupsCompanion.insert(
          id: group2Id,
          budgetId: budgetId2,
          name: 'Group 2',
          hidden: false,
          sortOrder: 1,
        ),
      );

      // Watch groups for budget 1
      final groups = await dao.watchGroupsByBudget(budgetId1).first;

      expect(groups, hasLength(1));
      expect(groups[0].id, equals(group1Id));
      expect(groups[0].name, equals('Group 1'));
      expect(groups[0].budgetId, equals(budgetId1));
    });

    test('watchCategoriesInGroup emits categories in sortOrder order',
        () async {
      // Seed budget and group
      const budgetId = 'budget-1';
      const groupId = 'group-1';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Budget 1',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );
      await dao.upsertGroup(
        CategoryGroupsCompanion.insert(
          id: groupId,
          budgetId: budgetId,
          name: 'Group 1',
          hidden: false,
          sortOrder: 1,
        ),
      );

      // Seed categories with different sortOrder
      await dao.upsertCategory(
        CategoriesCompanion.insert(
          id: 'cat-1',
          groupId: groupId,
          name: 'Category 1',
          hidden: false,
          sortOrder: 2,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        ),
      );
      await dao.upsertCategory(
        CategoriesCompanion.insert(
          id: 'cat-2',
          groupId: groupId,
          name: 'Category 2',
          hidden: false,
          sortOrder: 1,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        ),
      );

      // Watch categories in group
      final categories = await dao.watchCategoriesInGroup(groupId).first;

      expect(categories, hasLength(2));
      // Should be ordered by sortOrder
      expect(categories[0].id, equals('cat-2'));
      expect(categories[0].sortOrder, equals(1));
      expect(categories[1].id, equals('cat-1'));
      expect(categories[1].sortOrder, equals(2));
    });

    test('upsertCategory with same id updates name without duplication',
        () async {
      // Seed budget and group
      const budgetId = 'budget-1';
      const groupId = 'group-1';
      const catId = 'cat-1';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Budget 1',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );
      await dao.upsertGroup(
        CategoryGroupsCompanion.insert(
          id: groupId,
          budgetId: budgetId,
          name: 'Group 1',
          hidden: false,
          sortOrder: 1,
        ),
      );

      // Insert category
      await dao.upsertCategory(
        CategoriesCompanion.insert(
          id: catId,
          groupId: groupId,
          name: 'Original Name',
          hidden: false,
          sortOrder: 1,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        ),
      );

      // Verify initial state
      var cat = await dao.findCategoryById(catId);
      expect(cat?.name, equals('Original Name'));

      // Upsert with same id but different name
      await dao.upsertCategory(
        CategoriesCompanion.insert(
          id: catId,
          groupId: groupId,
          name: 'Updated Name',
          hidden: false,
          sortOrder: 1,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        ),
      );

      // Verify update
      cat = await dao.findCategoryById(catId);
      expect(cat?.name, equals('Updated Name'));

      // Verify no duplication - should still be only 1 category
      final categories = await dao.watchCategoriesInGroup(groupId).first;
      expect(categories, hasLength(1));
    });

    test('deleteCategory removes category and findCategoryById returns null',
        () async {
      // Seed budget and group
      const budgetId = 'budget-1';
      const groupId = 'group-1';
      const catId = 'cat-1';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Budget 1',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );
      await dao.upsertGroup(
        CategoryGroupsCompanion.insert(
          id: groupId,
          budgetId: budgetId,
          name: 'Group 1',
          hidden: false,
          sortOrder: 1,
        ),
      );
      await dao.upsertCategory(
        CategoriesCompanion.insert(
          id: catId,
          groupId: groupId,
          name: 'Category 1',
          hidden: false,
          sortOrder: 1,
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        ),
      );

      // Verify exists
      var cat = await dao.findCategoryById(catId);
      expect(cat, isNotNull);

      // Delete
      await dao.deleteCategory(catId);

      // Verify null
      cat = await dao.findCategoryById(catId);
      expect(cat, isNull);
    });

    test('deleteGroup removes group from watchGroupsByBudget', () async {
      // Seed budget
      const budgetId = 'budget-1';
      const groupId = 'group-1';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Budget 1',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );

      // Insert group
      await dao.upsertGroup(
        CategoryGroupsCompanion.insert(
          id: groupId,
          budgetId: budgetId,
          name: 'Group 1',
          hidden: false,
          sortOrder: 1,
        ),
      );

      // Verify exists
      var groups = await dao.watchGroupsByBudget(budgetId).first;
      expect(groups, hasLength(1));

      // Delete
      await dao.deleteGroup(groupId);

      // Verify removed
      groups = await dao.watchGroupsByBudget(budgetId).first;
      expect(groups, isEmpty);
    });
  });
}
