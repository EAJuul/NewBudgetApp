import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/budgets_table.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/category_budgets_table.dart';
import 'package:budget_app/data/database/tables/category_groups_table.dart';
import 'package:budget_app/data/database/tables/targets_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

part 'category_budgets_targets_test.g.dart';

@DriftDatabase(
  tables: [
    CategoryBudgets,
    Targets,
    Categories,
    CategoryGroups,
    Budgets,
    Accounts,
  ],
)
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

void main() {
  late _TestDb db;

  setUp(() => db = _TestDb());
  tearDown(() => db.close());

  test('CategoryBudgets: round-trips positive assigned', () async {
    await db.into(db.categoryBudgets).insert(
          CategoryBudgetsCompanion.insert(
            id: 'cb1',
            categoryId: 'cat1',
            month: '2026-05',
            assigned: 50000,
            createdAt: '2026-05-17T00:00:00Z',
            updatedAt: '2026-05-17T00:00:00Z',
          ),
        );
    final row = await db.select(db.categoryBudgets).getSingle();
    expect(row.assigned, 50000);
  });

  test('CategoryBudgets: round-trips negative assigned', () async {
    await db.into(db.categoryBudgets).insert(
          CategoryBudgetsCompanion.insert(
            id: 'cb2',
            categoryId: 'cat2',
            month: '2026-05',
            assigned: -10000,
            createdAt: '2026-05-17T00:00:00Z',
            updatedAt: '2026-05-17T00:00:00Z',
          ),
        );
    final row = await db.select(db.categoryBudgets).getSingle();
    expect(row.assigned, -10000);
  });

  test('CategoryBudgets: rejects duplicate (categoryId, month)', () async {
    await db.into(db.categoryBudgets).insert(
          CategoryBudgetsCompanion.insert(
            id: 'cb3',
            categoryId: 'cat3',
            month: '2026-05',
            assigned: 0,
            createdAt: '2026-05-17T00:00:00Z',
            updatedAt: '2026-05-17T00:00:00Z',
          ),
        );
    await expectLater(
      () => db.into(db.categoryBudgets).insert(
            CategoryBudgetsCompanion.insert(
              id: 'cb4',
              categoryId: 'cat3',
              month: '2026-05',
              assigned: 1000,
              createdAt: '2026-05-17T00:00:00Z',
              updatedAt: '2026-05-17T00:00:00Z',
            ),
          ),
      throwsA(anything),
    );
  });

  test('Targets: round-trips type and targetMonth', () async {
    await db.into(db.targets).insert(
          TargetsCompanion.insert(
            id: 't1',
            categoryId: 'cat4',
            type: TargetType.monthlyFunding,
            amount: 100000,
            createdAt: '2026-05-17T00:00:00Z',
            updatedAt: '2026-05-17T00:00:00Z',
          ),
        );
    await db.into(db.targets).insert(
          TargetsCompanion.insert(
            id: 't2',
            categoryId: 'cat5',
            type: TargetType.targetBalanceByDate,
            amount: 500000,
            targetMonth: const Value('2026-12'),
            createdAt: '2026-05-17T00:00:00Z',
            updatedAt: '2026-05-17T00:00:00Z',
          ),
        );
    final rows = await db.select(db.targets).get();
    final monthly = rows.firstWhere((r) => r.id == 't1');
    final byDate = rows.firstWhere((r) => r.id == 't2');
    expect(monthly.type, TargetType.monthlyFunding);
    expect(monthly.targetMonth, equals(null));
    expect(byDate.type, TargetType.targetBalanceByDate);
    expect(byDate.targetMonth, '2026-12');
  });

  test('Targets: rejects duplicate categoryId', () async {
    await db.into(db.targets).insert(
          TargetsCompanion.insert(
            id: 't3',
            categoryId: 'cat6',
            type: TargetType.targetBalance,
            amount: 0,
            createdAt: '2026-05-17T00:00:00Z',
            updatedAt: '2026-05-17T00:00:00Z',
          ),
        );
    await expectLater(
      () => db.into(db.targets).insert(
            TargetsCompanion.insert(
              id: 't4',
              categoryId: 'cat6',
              type: TargetType.monthlyFunding,
              amount: 1000,
              createdAt: '2026-05-17T00:00:00Z',
              updatedAt: '2026-05-17T00:00:00Z',
            ),
          ),
      throwsA(anything),
    );
  });
}
