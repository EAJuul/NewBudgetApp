import 'package:drift/drift.dart';

@DataClassName('CategoryBudgetRow')
class CategoryBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get month => text()(); // 'YYYY-MM'
  IntColumn get assigned => integer()(); // milliunits; may be negative
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month},
      ];
}
