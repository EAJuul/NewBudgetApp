import 'package:budget_app/data/daos/settings_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/settings/domain/settings_store.dart';
import 'package:drift/drift.dart';

class SettingsStoreImpl implements SettingsStore {
  SettingsStoreImpl(AppDatabase db) : _dao = SettingsDao(db);

  final SettingsDao _dao;

  @override
  Future<String?> get(String key) async {
    final row = await _dao.find(key);
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) =>
      _dao.put(SettingsCompanion(key: Value(key), value: Value(value)));

  @override
  Stream<String?> watch(String key) => _dao.watch(key).map((row) => row?.value);
}
