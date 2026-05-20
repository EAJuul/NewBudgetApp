import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:budget_app/data/database/tables/transactions_table.dart';
import 'package:drift/drift.dart';

@DataClassName('SubTransactionRow')
class SubTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  IntColumn get amount => integer()(); // signed milliunits
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get payeeId => text().nullable().references(Payees, #id)();
  TextColumn get memo => text().nullable()();
  BoolColumn get deleted => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
