import 'package:budget_app/data/daos/categories_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/categories/data/category_repository_impl.dart';
import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryRepositoryImpl', () {
    late AppDatabase db;
    late CategoryRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = CategoryRepositoryImpl(db);

      // Seed a budget for tests
      final now = DateTime.now().toUtc().toIso8601String();
      await db.into(db.budgets).insert(
            BudgetsCompanion(
              id: const Value('budget-1'),
              name: const Value('Test Budget'),
              currencyCode: const Value('USD'),
              currencyDecimalDigits: const Value(2),
              dateFormat: const Value('MM/dd/yyyy'),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      // Seed a category group for tests
      await db.into(db.categoryGroups).insert(
            const CategoryGroupsCompanion(
              id: Value('group-1'),
              budgetId: Value('budget-1'),
              name: Value('Expenses'),
              hidden: Value(false),
              sortOrder: Value(0),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'saveGroup then watchAllGroups emits the saved group as a domain CategoryGroup entity',
        () async {
      const group = CategoryGroup(
        id: 'group-2',
        budgetId: 'budget-1',
        name: 'Income',
        hidden: false,
        sortOrder: 1,
      );

      await repository.saveGroup(group);
      final groups = await repository.watchAllGroups('budget-1').first;

      expect(groups, hasLength(2));
      expect(groups[1].id, 'group-2');
      expect(groups[1].budgetId, 'budget-1');
      expect(groups[1].name, 'Income');
      expect(groups[1].hidden, isFalse);
      expect(groups[1].sortOrder, 1);
      expect(groups[1].systemType, isNull);
    });

    test(
        'saveCategory then findCategoryById returns the saved category as a domain Category entity',
        () async {
      const category = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        note: 'Food and drinks',
        sortOrder: 0,
      );

      await repository.saveCategory(category);
      final retrieved = await repository.findCategoryById('cat-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'cat-1');
      expect(retrieved.groupId, 'group-1');
      expect(retrieved.name, 'Groceries');
      expect(retrieved.hidden, isFalse);
      expect(retrieved.note, 'Food and drinks');
      expect(retrieved.sortOrder, 0);
      expect(retrieved.linkedAccountId, isNull);
    });

    test(
        'saveCategory twice with same id (changed name) updates the row and preserves original createdAt',
        () async {
      const category1 = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      await repository.saveCategory(category1);

      // Get the createdAt timestamp from the first save
      final dao = CategoriesDao(db);
      final row1 = await dao.findCategoryById('cat-1');
      final firstCreatedAt = row1!.createdAt;

      // Wait a tiny bit to ensure timestamps differ if they were regenerated
      await Future<void>.delayed(const Duration(milliseconds: 10));

      const category2 = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries and Essentials', // changed
        hidden: false,
        sortOrder: 0,
      );

      await repository.saveCategory(category2);

      // Verify the name was updated
      final retrieved = await repository.findCategoryById('cat-1');
      expect(retrieved!.name, 'Groceries and Essentials');

      // Verify createdAt is preserved
      final row2 = await dao.findCategoryById('cat-1');
      expect(row2!.createdAt, firstCreatedAt);
    });

    test('watchCategoriesInGroup emits categories ordered by sortOrder',
        () async {
      const cat1 = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 1,
      );

      const cat2 = Category(
        id: 'cat-2',
        groupId: 'group-1',
        name: 'Utilities',
        hidden: false,
        sortOrder: 0,
      );

      const cat3 = Category(
        id: 'cat-3',
        groupId: 'group-1',
        name: 'Transport',
        hidden: false,
        sortOrder: 2,
      );

      // Insert in non-sorted order
      await repository.saveCategory(cat1);
      await repository.saveCategory(cat3);
      await repository.saveCategory(cat2);

      final categories =
          await repository.watchCategoriesInGroup('group-1').first;

      expect(categories, hasLength(3));
      // Should be sorted by sortOrder
      expect(categories[0].id, 'cat-2'); // sortOrder 0
      expect(categories[1].id, 'cat-1'); // sortOrder 1
      expect(categories[2].id, 'cat-3'); // sortOrder 2
    });

    test(
        'deleteCategory removes the category and findCategoryById returns null',
        () async {
      const category = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      await repository.saveCategory(category);
      final retrieved = await repository.findCategoryById('cat-1');
      expect(retrieved, isNotNull);

      await repository.deleteCategory('cat-1');
      final deleted = await repository.findCategoryById('cat-1');
      expect(deleted, isNull);
    });

    test('deleteGroup removes the group and watchAllGroups emits empty list',
        () async {
      final groups1 = await repository.watchAllGroups('budget-1').first;
      expect(groups1, hasLength(1)); // Only the seeded group-1

      await repository.deleteGroup('group-1');

      final groups2 = await repository.watchAllGroups('budget-1').first;
      expect(groups2, isEmpty);
    });
  });
}
