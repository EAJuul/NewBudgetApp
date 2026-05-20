import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/targets/data/target_repository_impl.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );

void main() {
  late AppDatabase db;
  late TargetRepositoryImpl repo;

  setUp(() {
    db = _createTestDb();
    repo = TargetRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<void> seedParents() async {
    await db.into(db.budgets).insert(
          const BudgetsCompanion(
            id: Value('b1'),
            name: Value('Budget'),
            currencyCode: Value('USD'),
            currencyDecimalDigits: Value(2),
            dateFormat: Value('yyyy-MM-dd'),
            createdAt: Value('2024-01-01T00:00:00Z'),
            updatedAt: Value('2024-01-01T00:00:00Z'),
          ),
        );
    await db.into(db.categoryGroups).insert(
          const CategoryGroupsCompanion(
            id: Value('g1'),
            budgetId: Value('b1'),
            name: Value('Bills'),
            hidden: Value(false),
            sortOrder: Value(0),
          ),
        );
    await db.into(db.categories).insert(
          const CategoriesCompanion(
            id: Value('cat1'),
            groupId: Value('g1'),
            name: Value('Rent'),
            hidden: Value(false),
            sortOrder: Value(0),
            createdAt: Value('2024-01-01T00:00:00Z'),
            updatedAt: Value('2024-01-01T00:00:00Z'),
          ),
        );
  }

  Target makeTarget({
    String id = 't1',
    String categoryId = 'cat1',
    TargetType type = TargetType.monthlyFunding,
    int milliunits = 50000,
    MonthKey? targetMonth,
  }) =>
      Target(
        id: id,
        categoryId: categoryId,
        type: type,
        amount: Money(milliunits),
        targetMonth: targetMonth,
      );

  test(
    'save then findForCategory returns entity with Money and MonthKey intact',
    () async {
      await seedParents();
      final target = makeTarget(
        type: TargetType.targetBalanceByDate,
        milliunits: 100000,
        targetMonth: const MonthKey(2024, 12),
      );
      await repo.save(target);

      final found = await repo.findForCategory('cat1');
      expect(found, isNotNull);
      expect(found!.amount, const Money(100000));
      expect(found.targetMonth, const MonthKey(2024, 12));
      expect(found.type, TargetType.targetBalanceByDate);
    },
  );

  test(
    'save twice for same category updates row; only one target exists',
    () async {
      await seedParents();
      await repo.save(makeTarget());
      await repo.save(makeTarget(milliunits: 75000));

      final found = await repo.findForCategory('cat1');
      expect(found!.amount, const Money(75000));

      final all = await repo.watchAll().first;
      expect(all, hasLength(1));
    },
  );

  test(
    'watchAll emits all targets',
    () async {
      await seedParents();
      // Add a second category
      await db.into(db.categories).insert(
            const CategoriesCompanion(
              id: Value('cat2'),
              groupId: Value('g1'),
              name: Value('Groceries'),
              hidden: Value(false),
              sortOrder: Value(1),
              createdAt: Value('2024-01-01T00:00:00Z'),
              updatedAt: Value('2024-01-01T00:00:00Z'),
            ),
          );

      await repo.save(makeTarget());
      await repo.save(makeTarget(id: 't2', categoryId: 'cat2'));

      final all = await repo.watchAll().first;
      expect(all.map((t) => t.categoryId).toSet(), {'cat1', 'cat2'});
    },
  );

  test(
    'deleteForCategory removes the target',
    () async {
      await seedParents();
      await repo.save(makeTarget());
      await repo.deleteForCategory('cat1');
      final found = await repo.findForCategory('cat1');
      expect(found, isNull);
    },
  );
}
