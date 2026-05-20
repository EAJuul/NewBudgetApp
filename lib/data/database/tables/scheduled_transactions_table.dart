import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';

@DataClassName('ScheduledTransactionRow')
class ScheduledTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get amount => integer()(); // signed milliunits
  TextColumn get payeeId => text().nullable().references(Payees, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get memo => text().nullable()();
  TextColumn get frequency => textEnum<ScheduleFrequency>()();
  TextColumn get nextDate => text()(); // 'YYYY-MM-DD'
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
