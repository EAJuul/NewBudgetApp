import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:drift/drift.dart';

CategoryBudget categoryBudgetFromRow(CategoryBudgetRow row) => CategoryBudget(
      id: row.id,
      categoryId: row.categoryId,
      month: MonthKey.parse(row.month),
      assigned: Money(row.assigned),
    );

CategoryBudgetsCompanion categoryBudgetToCompanion(
  CategoryBudget budget, {
  required String createdAt,
  required String updatedAt,
}) =>
    CategoryBudgetsCompanion(
      id: Value(budget.id),
      categoryId: Value(budget.categoryId),
      month: Value(budget.month.toIso()),
      assigned: Value(budget.assigned.milliunits),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
