import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:drift/drift.dart';

Account accountFromRow(AccountRow row) => Account(
      id: row.id,
      budgetId: row.budgetId,
      name: row.name,
      type: row.type,
      onBudget: row.onBudget,
      closed: row.closed,
      note: row.note,
      sortOrder: row.sortOrder,
    );

AccountsCompanion accountToCompanion(
  Account account, {
  required String createdAt,
  required String updatedAt,
}) =>
    AccountsCompanion(
      id: Value(account.id),
      budgetId: Value(account.budgetId),
      name: Value(account.name),
      type: Value(account.type),
      onBudget: Value(account.onBudget),
      closed: Value(account.closed),
      note: Value(account.note),
      sortOrder: Value(account.sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
