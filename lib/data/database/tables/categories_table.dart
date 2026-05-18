import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/category_groups_table.dart';
import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(CategoryGroups, #id)();
  TextColumn get name => text()();
  BoolColumn get hidden => boolean()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer()();
  TextColumn get linkedAccountId =>
      text().nullable().references(Accounts, #id)();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
