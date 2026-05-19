import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/data/daos/category_budgets_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/budget/data/category_budget_mappers.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:budget_app/features/budget/domain/category_budget_repository.dart';

class CategoryBudgetRepositoryImpl implements CategoryBudgetRepository {
  CategoryBudgetRepositoryImpl(AppDatabase db) : _dao = CategoryBudgetsDao(db);

  final CategoryBudgetsDao _dao;

  @override
  Stream<List<CategoryBudget>> watchForCategory(String categoryId) =>
      _dao.watchForCategory(categoryId).map(
            (rows) => rows.map(categoryBudgetFromRow).toList(),
          );

  @override
  Stream<List<CategoryBudget>> watchForMonth(MonthKey month) =>
      _dao.watchForMonth(month.toIso()).map(
            (rows) => rows.map(categoryBudgetFromRow).toList(),
          );

  @override
  Future<CategoryBudget?> find(String categoryId, MonthKey month) async {
    final row = await _dao.find(categoryId, month.toIso());
    return row == null ? null : categoryBudgetFromRow(row);
  }

  @override
  Future<void> save(CategoryBudget budget) async {
    final existing = await _dao.find(budget.categoryId, budget.month.toIso());
    final now = DateTime.now().toUtc().toIso8601String();
    final createdAt = existing?.createdAt ?? now;
    await _dao.upsert(
      categoryBudgetToCompanion(budget, createdAt: createdAt, updatedAt: now),
    );
  }
}
