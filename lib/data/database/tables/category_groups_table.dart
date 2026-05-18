import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';

@DataClassName('CategoryGroupRow')
class CategoryGroups extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  TextColumn get name => text()();
  BoolColumn get hidden => boolean()();
  IntColumn get sortOrder => integer()();
  TextColumn get systemType => textEnum<SystemGroupType>().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
