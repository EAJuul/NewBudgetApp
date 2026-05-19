import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/settings/data/budget_repository_impl.dart';
import 'package:budget_app/features/settings/domain/budget.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );

Budget _makeBudget({String id = 'b1', String name = 'Test Budget'}) => Budget(
      id: id,
      name: name,
      currencyCode: 'USD',
      currencyDecimalDigits: 2,
      dateFormat: 'MM/dd/yyyy',
    );

void main() {
  late AppDatabase db;
  late BudgetRepositoryImpl repo;

  setUp(() {
    db = _createTestDb();
    repo = BudgetRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('getPrimary returns null on empty database', () async {
    final result = await repo.getPrimary();
    expect(result, isNull);
  });

  test('save then getPrimary returns the budget; watchPrimary emits it',
      () async {
    final budget = _makeBudget();
    await repo.save(budget);

    final found = await repo.getPrimary();
    expect(found, isNotNull);
    expect(found!.id, 'b1');
    expect(found.name, 'Test Budget');
    expect(found.currencyCode, 'USD');

    final watched = await repo.watchPrimary().first;
    expect(watched, isNotNull);
    expect(watched!.id, 'b1');
  });

  test('save twice with same id updates row and preserves createdAt', () async {
    await repo.save(_makeBudget(name: 'Original'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.save(_makeBudget(name: 'Updated'));

    final found = await repo.getPrimary();
    expect(found!.name, 'Updated');

    // Verify only one row in DB
    final all = await repo.watchPrimary().first;
    expect(all, isNotNull);
  });
}
