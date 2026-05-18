import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:drift/drift.dart';

@DataClassName('PayeeRow')
class Payees extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  TextColumn get name => text()();
  TextColumn get defaultCategoryId =>
      text().nullable().references(Categories, #id)();
  TextColumn get transferAccountId =>
      text().nullable().references(Accounts, #id)();

  @override
  Set<Column> get primaryKey => {id};
}
