import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/category_groups_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

part 'category_groups_categories_test.g.dart';

@DriftDatabase(tables: [CategoryGroups, Categories])
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

void main() {
  const uuid = Uuid();
  const timestamp = '2026-05-16T12:00:00Z';

  group('CategoryGroups and Categories tables', () {
    late _TestDb db;
    const budgetId = 'budget-1';

    setUp(() => db = _TestDb());

    tearDown(() => db.close());

    test('null systemType round-trips', () async {
      final groupId = uuid.v4();
      await db.into(db.categoryGroups).insert(
            CategoryGroupsCompanion.insert(
              id: groupId,
              budgetId: budgetId,
              name: 'Monthly Bills',
              hidden: false,
              sortOrder: 0,
            ),
          );

      final row = await (db.select(db.categoryGroups)
            ..where((t) => t.id.equals(groupId)))
          .getSingle();
      expect(row.systemType, null);
    });

    test('systemType round-trips via textEnum', () async {
      final groupId = uuid.v4();
      await db.into(db.categoryGroups).insert(
            CategoryGroupsCompanion.insert(
              id: groupId,
              budgetId: budgetId,
              name: 'Credit Card Payments',
              hidden: false,
              sortOrder: 0,
              systemType: const Value(SystemGroupType.creditCardPayments),
            ),
          );

      final row = await (db.select(db.categoryGroups)
            ..where((t) => t.id.equals(groupId)))
          .getSingle();
      expect(row.systemType, SystemGroupType.creditCardPayments);
    });

    test('nullable linkedAccountId round-trips as null', () async {
      final groupId = uuid.v4();
      await db.into(db.categoryGroups).insert(
            CategoryGroupsCompanion.insert(
              id: groupId,
              budgetId: budgetId,
              name: 'Everyday',
              hidden: false,
              sortOrder: 0,
            ),
          );

      final categoryId = uuid.v4();
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: categoryId,
              groupId: groupId,
              name: 'Groceries',
              hidden: false,
              sortOrder: 0,
              linkedAccountId: const Value(null),
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      final row = await (db.select(db.categories)
            ..where((t) => t.id.equals(categoryId)))
          .getSingle();
      expect(row.linkedAccountId, null);
    });

    test('groupId and hidden round-trip', () async {
      final groupId = uuid.v4();
      await db.into(db.categoryGroups).insert(
            CategoryGroupsCompanion.insert(
              id: groupId,
              budgetId: budgetId,
              name: 'Goals',
              hidden: false,
              sortOrder: 1,
            ),
          );

      final categoryId = uuid.v4();
      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: categoryId,
              groupId: groupId,
              name: 'Vacation',
              hidden: false,
              sortOrder: 0,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      final row = await (db.select(db.categories)
            ..where((t) => t.id.equals(categoryId)))
          .getSingle();
      expect(row.groupId, groupId);
      expect(row.hidden, isFalse);
    });
  });
}
