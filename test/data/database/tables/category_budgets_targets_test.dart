import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/test_helpers.dart';

@DriftDatabase(tables: [CategoryBudgets, Targets])
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 1;
}

void main() {
  late _TestDb db;

  setUp(() {
    db = _TestDb();
  });

  tearDown(() {
    db.close();
  });

  test('Insert and select a category budget with positive assigned', () async {
    final budget = CategoryBudgetsCompanion(
      id: '1',
      categoryId: '1',
      month: '2023-01',
      assigned: 1000,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await db.into(db.categoryBudgets).insert(budget);

    final result = await db.select(db.categoryBudgets).get();

    expect(result, hasLength(1));
    expect(result.first.assigned, equals(1000));
  });

  test('Insert a category budget with negative assigned', () async {
    final budget = CategoryBudgetsCompanion(
      id: '2',
      categoryId: '2',
      month: '2023-01',
      assigned: -500,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await db.into(db.categoryBudgets).insert(budget);

    final result = await db.select(db.categoryBudgets).get();

    expect(result, hasLength(1));
    expect(result.first.assigned, equals(-500));
  });

  test('Insert two category budgets with the same category ID and month', () async {
    final budget1 = CategoryBudgetsCompanion(
      id: '3',
      categoryId: '3',
      month: '2023-01',
      assigned: 1000,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await db.into(db.categoryBudgets).insert(budget1);

    final budget2 = CategoryBudgetsCompanion(
      id: '4',
      categoryId: '3',
      month: '2023-01',
      assigned: 2000,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await expectLater(
      db.into(db.categoryBudgets).insert(budget2),
      throwsA(isA<DatabaseException>().that(hasMessage(contains('UNIQUE constraint failed')))),
    );
  });

  test('Insert a target for TargetType.monthlyFunding with targetMonth null', () async {
    final target = TargetsCompanion(
      id: '1',
      categoryId: '1',
      type: TargetType.monthlyFunding.name,
      amount: 1000,
      targetMonth: null,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await db.into(db.targets).insert(target);

    final result = await db.select(db.targets).get();

    expect(result, hasLength(1));
    expect(result.first.type, equals(TargetType.monthlyFunding.name));
    expect(result.first.targetMonth, isNull);
  });

  test('Insert a target for TargetType.targetBalanceByDate with targetMonth non-null', () async {
    final target = TargetsCompanion(
      id: '2',
      categoryId: '2',
      type: TargetType.targetBalanceByDate.name,
      amount: 2000,
      targetMonth: '2023-01',
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await db.into(db.targets).insert(target);

    final result = await db.select(db.targets).get();

    expect(result, hasLength(1));
    expect(result.first.type, equals(TargetType.targetBalanceByDate.name));
    expect(result.first.targetMonth, equals('2023-01'));
  });

  test('Insert two targets with the same category ID', () async {
    final target1 = TargetsCompanion(
      id: '3',
      categoryId: '3',
      type: TargetType.monthlyFunding.name,
      amount: 1000,
      targetMonth: null,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await db.into(db.targets).insert(target1);

    final target2 = TargetsCompanion(
      id: '4',
      categoryId: '3',
      type: TargetType.monthlyFunding.name,
      amount: 2000,
      targetMonth: null,
      createdAt: '2023-01-01T00:00:00Z',
      updatedAt: '2023-01-01T00:00:00Z',
    );

    await expectLater(
      db.into(db.targets).insert(target2),
      throwsA(isA<DatabaseException>().that(hasMessage(contains('UNIQUE constraint failed')))),
    );
  });
}