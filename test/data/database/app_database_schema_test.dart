import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('database opens with schemaVersion 1', () {
    expect(db.schemaVersion, 1);
  });

  test('all eleven tables exist and are empty', () async {
    expect(await db.select(db.budgets).get(), isEmpty);
    expect(await db.select(db.accounts).get(), isEmpty);
    expect(await db.select(db.categoryGroups).get(), isEmpty);
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.categoryBudgets).get(), isEmpty);
    expect(await db.select(db.targets).get(), isEmpty);
    expect(await db.select(db.payees).get(), isEmpty);
    expect(await db.select(db.settings).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.subTransactions).get(), isEmpty);
    expect(await db.select(db.scheduledTransactions).get(), isEmpty);
  });

  test('insert budget then account referencing it succeeds', () async {
    await db.into(db.budgets).insert(
          BudgetsCompanion.insert(
            id: 'b1',
            name: 'My Budget',
            currencyCode: 'USD',
            currencyDecimalDigits: 2,
            dateFormat: 'MM/dd/yyyy',
            createdAt: '2026-01-01T00:00:00Z',
            updatedAt: '2026-01-01T00:00:00Z',
          ),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'a1',
            budgetId: 'b1',
            name: 'Checking',
            type: AccountType.checking,
            onBudget: true,
            closed: false,
            sortOrder: 0,
            createdAt: '2026-01-01T00:00:00Z',
            updatedAt: '2026-01-01T00:00:00Z',
          ),
        );
    final accounts = await db.select(db.accounts).get();
    expect(accounts.length, 1);
  });

  test('insert account with non-existent budgetId throws (FK enforced)',
      () async {
    await expectLater(
      () => db.into(db.accounts).insert(
            AccountsCompanion.insert(
              id: 'a2',
              budgetId: 'does-not-exist',
              name: 'Savings',
              type: AccountType.savings,
              onBudget: true,
              closed: false,
              sortOrder: 0,
              createdAt: '2026-01-01T00:00:00Z',
              updatedAt: '2026-01-01T00:00:00Z',
            ),
          ),
      throwsA(anything),
    );
  });

  test('insert transaction with non-existent accountId throws (FK enforced)',
      () async {
    await expectLater(
      () => db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx1',
              accountId: 'does-not-exist',
              date: '2026-01-01',
              amount: -5000,
              cleared: ClearedStatus.uncleared,
              approved: true,
              isSplit: false,
              deleted: false,
              createdAt: '2026-01-01T00:00:00Z',
              updatedAt: '2026-01-01T00:00:00Z',
            ),
          ),
      throwsA(anything),
    );
  });
}
