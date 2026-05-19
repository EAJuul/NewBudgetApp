import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/targets_table.dart';
import 'package:drift/drift.dart';

part 'targets_dao.g.dart';

@DriftAccessor(tables: [Targets])
class TargetsDao extends DatabaseAccessor<AppDatabase> with _$TargetsDaoMixin {
  TargetsDao(super.attachedDatabase);

  Stream<List<TargetRow>> watchAll() => select(targets).watch();

  Future<TargetRow?> findByCategory(String categoryId) =>
      (select(targets)..where((t) => t.categoryId.equals(categoryId)))
          .getSingleOrNull();

  Future<void> upsert(TargetsCompanion target) =>
      into(targets).insertOnConflictUpdate(target);

  Future<void> deleteByCategory(String categoryId) =>
      (delete(targets)..where((t) => t.categoryId.equals(categoryId))).go();
}
