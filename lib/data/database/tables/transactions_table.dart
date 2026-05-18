import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:budget_app/data/database/tables/scheduled_transactions_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get date => text()(); // 'YYYY-MM-DD'
  IntColumn get amount => integer()(); // signed milliunits
  TextColumn get payeeId => text().nullable().references(Payees, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get memo => text().nullable()();
  TextColumn get cleared => textEnum<ClearedStatus>()();
  BoolColumn get approved => boolean()();
  TextColumn get flagColor => textEnum<FlagColor>().nullable()();
  TextColumn get transferTransactionId =>
      text().nullable().references(Transactions, #id)();
  TextColumn get transferAccountId =>
      text().nullable().references(Accounts, #id)();
  TextColumn get scheduledTransactionId =>
      text().nullable().references(ScheduledTransactions, #id)();
  TextColumn get importId => text().nullable()();
  BoolColumn get isSplit => boolean()();
  BoolColumn get deleted => boolean()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
