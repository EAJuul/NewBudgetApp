import 'package:budget_app/data/database/tables/transactions_table.dart';
import 'package:drift/drift.dart';

@DataClassName('SubTransactionRow')
class SubTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  IntColumn get amount => integer()(); // signed milliunits
  TextColumn get categoryId => text().nullable()();
  TextColumn get payeeId => text().nullable()();
  TextColumn get memo => text().nullable()();
  BoolColumn get deleted => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
