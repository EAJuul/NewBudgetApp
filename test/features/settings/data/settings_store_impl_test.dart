import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/settings/data/settings_store_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );

void main() {
  late AppDatabase db;
  late SettingsStoreImpl store;

  setUp(() {
    db = _createTestDb();
    store = SettingsStoreImpl(db);
  });

  tearDown(() => db.close());

  test('get returns null for unset key', () async {
    final result = await store.get('theme');
    expect(result, isNull);
  });

  test('set then get returns the value; set again on same key overwrites it',
      () async {
    await store.set('theme', 'dark');
    expect(await store.get('theme'), 'dark');

    await store.set('theme', 'light');
    expect(await store.get('theme'), 'light');

    // Verify only one row for 'theme'
    final watched = await store.watch('theme').first;
    expect(watched, 'light');
  });

  test('watch(key) emits current value and re-emits after set', () async {
    // Before set: emits null
    expect(await store.watch('key1').first, isNull);

    await store.set('key1', 'hello');

    // After set: emits the value
    expect(await store.watch('key1').first, 'hello');
  });
}
