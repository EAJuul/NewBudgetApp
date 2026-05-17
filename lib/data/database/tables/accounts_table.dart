import 'package:budget_app/data/database/tables/budgets_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text().references(Budgets, #id)();
  TextColumn get name => text()();
  TextColumn get type => textEnum<AccountType>()();
  BoolColumn get onBudget => boolean()();
  BoolColumn get closed => boolean()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
