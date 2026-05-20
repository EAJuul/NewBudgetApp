import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/data/daos/category_budgets_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/budget/data/category_budget_repository_impl.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryBudgetRepositoryImpl', () {
    late AppDatabase db;
    late CategoryBudgetRepositoryImpl repository;
    late CategoryBudgetsDao dao;
    late String budgetId;
    late String groupId;
    late String categoryId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = CategoryBudgetRepositoryImpl(db);
      dao = CategoryBudgetsDao(db);

      // Seed budget
      budgetId = 'budget-1';
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Test Budget',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'yyyy-MM-dd',
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );

      // Seed category group
      groupId = 'group-1';
      await db.into(db.categoryGroups).insert(
            CategoryGroupsCompanion.insert(
              id: groupId,
              budgetId: budgetId,
              name: 'Test Group',
              hidden: false,
              sortOrder: 1,
            ),
          );

      // Seed category (required for FK)
      categoryId = 'cat-1';
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: categoryId,
              groupId: groupId,
              name: 'Test Category',
              hidden: false,
              sortOrder: 1,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );
    });

    tearDown(() => db.close());

    test(
        'save then find returns CategoryBudget with correct MonthKey and Money',
        () async {
      final budget = CategoryBudget(
        id: 'cb-1',
        categoryId: categoryId,
        month: const MonthKey(2026, 5),
        assigned: const Money(50000),
      );

      await repository.save(budget);
      final found = await repository.find(categoryId, const MonthKey(2026, 5));

      expect(found, isNotNull);
      expect(found!.id, 'cb-1');
      expect(found.categoryId, categoryId);
      expect(found.month, const MonthKey(2026, 5));
      expect(found.assigned, const Money(50000));
    });

    test(
        'save same (categoryId, month) twice with different assigned; find returns updated value; only one row',
        () async {
      const month = MonthKey(2026, 6);
      final budget1 = CategoryBudget(
        id: 'cb-1',
        categoryId: categoryId,
        month: month,
        assigned: const Money(50000),
      );

      await repository.save(budget1);
      var found = await repository.find(categoryId, month);
      expect(found!.assigned, const Money(50000));

      // Save again with different assigned
      final budget2 = CategoryBudget(
        id: 'cb-1',
        categoryId: categoryId,
        month: month,
        assigned: const Money(75000),
      );

      await repository.save(budget2);
      found = await repository.find(categoryId, month);
      expect(found!.assigned, const Money(75000));

      // Verify only one row exists
      final rows = await dao.find(categoryId, month.toIso());
      expect(rows, isNotNull);
      expect(rows!.assigned, 75000);
    });

    test('negative assigned round-trips correctly', () async {
      final budget = CategoryBudget(
        id: 'cb-1',
        categoryId: categoryId,
        month: const MonthKey(2026, 7),
        assigned: const Money(-3000),
      );

      await repository.save(budget);
      final found = await repository.find(categoryId, const MonthKey(2026, 7));

      expect(found, isNotNull);
      expect(found!.assigned.milliunits, -3000);
      expect(found.assigned, const Money(-3000));
    });

    test('watchForMonth returns only that month assignments', () async {
      const cat2Id = 'cat-2';
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: cat2Id,
              groupId: groupId,
              name: 'Category 2',
              hidden: false,
              sortOrder: 2,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );

      // Save budgets for different months and categories
      const month1 = MonthKey(2026, 5);
      const month2 = MonthKey(2026, 6);

      await repository.save(
        CategoryBudget(
          id: 'cb-1',
          categoryId: categoryId,
          month: month1,
          assigned: const Money(50000),
        ),
      );

      await repository.save(
        CategoryBudget(
          id: 'cb-2',
          categoryId: categoryId,
          month: month2,
          assigned: const Money(60000),
        ),
      );

      await repository.save(
        const CategoryBudget(
          id: 'cb-3',
          categoryId: cat2Id,
          month: month1,
          assigned: Money(40000),
        ),
      );

      // Watch for month1
      final month1Budgets =
          await repository.watchForMonth(month1).first.timeout(
                const Duration(seconds: 5),
              );

      expect(month1Budgets, hasLength(2));
      expect(month1Budgets.every((b) => b.month == month1), true);
    });

    test('watchForCategory returns only that category assignments', () async {
      const cat2Id = 'cat-2';
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: cat2Id,
              groupId: groupId,
              name: 'Category 2',
              hidden: false,
              sortOrder: 2,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
            ),
          );

      // Save budgets for different months and categories
      const month1 = MonthKey(2026, 5);
      const month2 = MonthKey(2026, 6);

      await repository.save(
        CategoryBudget(
          id: 'cb-1',
          categoryId: categoryId,
          month: month1,
          assigned: const Money(50000),
        ),
      );

      await repository.save(
        CategoryBudget(
          id: 'cb-2',
          categoryId: categoryId,
          month: month2,
          assigned: const Money(60000),
        ),
      );

      await repository.save(
        const CategoryBudget(
          id: 'cb-3',
          categoryId: cat2Id,
          month: month1,
          assigned: Money(40000),
        ),
      );

      // Watch for categoryId
      final categoryBudgets = await repository
          .watchForCategory(categoryId)
          .first
          .timeout(const Duration(seconds: 5));

      expect(categoryBudgets, hasLength(2));
      expect(categoryBudgets.every((b) => b.categoryId == categoryId), true);
    });
  });
}
