import 'package:drift/drift.dart';

@DataClassName('PayeeRow')
class Payees extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  TextColumn get name => text()();
  TextColumn get defaultCategoryId => text().nullable()();
  TextColumn get transferAccountId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
