import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';

@DataClassName('ScheduledTransactionRow')
class ScheduledTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  IntColumn get amount => integer()(); // signed milliunits
  TextColumn get payeeId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get frequency => textEnum<ScheduleFrequency>()();
  TextColumn get nextDate => text()(); // 'YYYY-MM-DD'
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
