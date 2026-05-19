import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/settings/domain/budget.dart';
import 'package:drift/drift.dart';

Budget budgetFromRow(BudgetRow row) => Budget(
      id: row.id,
      name: row.name,
      currencyCode: row.currencyCode,
      currencyDecimalDigits: row.currencyDecimalDigits,
      dateFormat: row.dateFormat,
    );

BudgetsCompanion budgetToCompanion(
  Budget budget, {
  required String createdAt,
  required String updatedAt,
}) =>
    BudgetsCompanion(
      id: Value(budget.id),
      name: Value(budget.name),
      currencyCode: Value(budget.currencyCode),
      currencyDecimalDigits: Value(budget.currencyDecimalDigits),
      dateFormat: Value(budget.dateFormat),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
