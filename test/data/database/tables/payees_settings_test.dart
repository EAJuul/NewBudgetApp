import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:budget_app/data/database/tables/settings_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

part 'payees_settings_test.g.dart';

@DriftDatabase(tables: [Payees, Settings])
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

void main() {
  const uuid = Uuid();

  group('Payees and Settings tables', () {
    late _TestDb db;
    const budgetId = 'budget-1';

    setUp(() => db = _TestDb());

    tearDown(() => db.close());

    test(
        'insert payee with both nullable columns null; read back and assert both null',
        () async {
      final payeeId = uuid.v4();
      await db.into(db.payees).insert(
            PayeesCompanion.insert(
              id: payeeId,
              budgetId: budgetId,
              name: 'Grocery Store',
            ),
          );

      final row = await (db.select(db.payees)
            ..where((t) => t.id.equals(payeeId)))
          .getSingle();
      expect(row.defaultCategoryId, null);
      expect(row.transferAccountId, null);
    });

    test('insert payee with non-null transferAccountId; verify it round-trips',
        () async {
      final payeeId = uuid.v4();
      await db.into(db.payees).insert(
            PayeesCompanion.insert(
              id: payeeId,
              budgetId: budgetId,
              name: 'Savings Account',
              transferAccountId: const Value('transfer-account-1'),
            ),
          );

      final row = await (db.select(db.payees)
            ..where((t) => t.id.equals(payeeId)))
          .getSingle();
      expect(row.transferAccountId, 'transfer-account-1');
    });

    test(
        'insert two Settings rows with distinct keys; verify both selectable by key',
        () async {
      const key1 = 'theme';
      const value1 = 'dark';
      const key2 = 'language';
      const value2 = 'en';

      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              key: key1,
              value: value1,
            ),
          );

      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              key: key2,
              value: value2,
            ),
          );

      final row1 = await (db.select(db.settings)
            ..where((t) => t.key.equals(key1)))
          .getSingle();
      final row2 = await (db.select(db.settings)
            ..where((t) => t.key.equals(key2)))
          .getSingle();

      expect(row1.value, value1);
      expect(row2.value, value2);
    });

    test(
        'insert settings row, insert again with same key; second insert should throw',
        () async {
      const key = 'currency';
      const value1 = 'USD';
      const value2 = 'EUR';

      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              key: key,
              value: value1,
            ),
          );

      expect(
        () => db.into(db.settings).insert(
              SettingsCompanion.insert(
                key: key,
                value: value2,
              ),
            ),
        throwsA(anything),
      );
    });
  });
}
