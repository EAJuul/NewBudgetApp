import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/payees/data/payee_repository_impl.dart';
import 'package:budget_app/features/payees/domain/payee.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );

Payee _makePayee({
  String id = 'p1',
  String budgetId = 'b1',
  String name = 'Amazon',
  String? transferAccountId,
}) =>
    Payee(
      id: id,
      budgetId: budgetId,
      name: name,
      transferAccountId: transferAccountId,
    );

void main() {
  late AppDatabase db;
  late PayeeRepositoryImpl repo;

  setUp(() {
    db = _createTestDb();
    repo = PayeeRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('save then findById returns domain entity', () async {
    final payee = _makePayee();
    await repo.save(payee);
    final found = await repo.findById('p1');
    expect(found, isNotNull);
    expect(found!.id, 'p1');
    expect(found.name, 'Amazon');
    expect(found.budgetId, 'b1');
  });

  test('save twice with same id updates row, no duplicate', () async {
    await repo.save(_makePayee());
    await repo.save(_makePayee(name: 'Amazon Updated'));
    final found = await repo.findById('p1');
    expect(found!.name, 'Amazon Updated');
    final all = await repo.watchAll('b1').first;
    expect(all.length, 1);
  });

  test('watchAll emits budget payees, excludes other budget', () async {
    await repo.save(_makePayee());
    await repo.save(_makePayee(id: 'p2', name: 'Starbucks'));
    await repo.save(_makePayee(id: 'p3', budgetId: 'b2', name: 'Other'));

    final rows = await repo.watchAll('b1').first;
    expect(rows.map((p) => p.id).toSet(), {'p1', 'p2'});
    expect(rows.map((p) => p.id), isNot(contains('p3')));
  });

  test('delete removes the payee', () async {
    await repo.save(_makePayee());
    await repo.delete('p1');
    final found = await repo.findById('p1');
    expect(found, isNull);
  });
}
