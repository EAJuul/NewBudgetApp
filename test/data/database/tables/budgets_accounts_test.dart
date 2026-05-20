import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/budgets_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

part 'budgets_accounts_test.g.dart';

@DriftDatabase(tables: [Budgets, Accounts])
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

void main() {
  const uuid = Uuid();
  const timestamp = '2026-05-16T12:00:00Z';

  group('Budgets and Accounts tables', () {
    late _TestDb db;
    late String budgetId;

    setUp(() async {
      db = _TestDb();
      budgetId = uuid.v4();
      await db.into(db.budgets).insert(
            BudgetsCompanion.insert(
              id: budgetId,
              name: 'Test Budget',
              currencyCode: 'USD',
              currencyDecimalDigits: 2,
              dateFormat: 'MM/dd/yyyy',
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );
    });

    tearDown(() => db.close());

    test('budget row round-trips currency fields', () async {
      final row = await (db.select(db.budgets)
            ..where((t) => t.id.equals(budgetId)))
          .getSingle();

      expect(row.currencyCode, 'USD');
      expect(row.currencyDecimalDigits, 2);
    });

    test('account type round-trips via textEnum', () async {
      final types = [
        AccountType.checking,
        AccountType.creditCard,
        AccountType.asset,
      ];

      for (final (index, type) in types.indexed) {
        final id = uuid.v4();
        await db.into(db.accounts).insert(
              AccountsCompanion.insert(
                id: id,
                budgetId: budgetId,
                name: 'Account $index',
                type: type,
                onBudget: type.isOnBudget,
                closed: false,
                sortOrder: index,
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
            );

        final row = await (db.select(db.accounts)
              ..where((t) => t.id.equals(id)))
            .getSingle();
        expect(row.type, type);
      }
    });

    test('nullable note round-trips as null', () async {
      final id = uuid.v4();
      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              id: id,
              budgetId: budgetId,
              name: 'No note',
              type: AccountType.savings,
              onBudget: true,
              closed: false,
              note: const Value(null),
              sortOrder: 0,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      final row = await (db.select(db.accounts)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.note, null);
    });

    test('boolean columns round-trip', () async {
      final id = uuid.v4();
      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              id: id,
              budgetId: budgetId,
              name: 'Checking',
              type: AccountType.checking,
              onBudget: true,
              closed: false,
              sortOrder: 0,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          );

      final row = await (db.select(db.accounts)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.onBudget, isTrue);
      expect(row.closed, isFalse);
    });
  });
}
