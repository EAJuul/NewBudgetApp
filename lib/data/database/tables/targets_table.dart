import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';

@DataClassName('TargetRow')
class Targets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get type => textEnum<TargetType>()();
  IntColumn get amount => integer()();
  TextColumn get targetMonth => text().nullable()(); // 'YYYY-MM'
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId},
      ];
}
