import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/database/tables/settings_table.dart';
import 'package:drift/drift.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Future<SettingRow?> find(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();

  Stream<SettingRow?> watch(String key) =>
      (select(settings)..where((s) => s.key.equals(key))).watchSingleOrNull();

  Future<void> put(SettingsCompanion setting) =>
      into(settings).insertOnConflictUpdate(setting);
}
