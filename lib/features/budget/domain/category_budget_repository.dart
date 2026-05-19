import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';

abstract interface class CategoryBudgetRepository {
  Stream<List<CategoryBudget>> watchForCategory(String categoryId);
  Stream<List<CategoryBudget>> watchForMonth(MonthKey month);
  Future<CategoryBudget?> find(String categoryId, MonthKey month);
  Future<void> save(CategoryBudget budget);
}
