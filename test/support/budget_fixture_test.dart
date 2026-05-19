import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_fixture.dart';

void main() {
  group('BudgetFixture', () {
    test('create returns fixture with empty snapshots', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final accounts = await fixture.allAccounts();
      final txns = await fixture.allTransactions();
      expect(accounts, isEmpty);
      expect(txns, isEmpty);
    });

    test('addAccount + addCategory + addTransaction appear in snapshots',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final category = await fixture.addCategory(
        groupId: group.id,
        name: 'Rent',
      );
      await fixture.assign(
        categoryId: category.id,
        month: const MonthKey(2024, 3),
        amount: const Money(500000),
      );
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(-100000),
        categoryId: category.id,
      );

      final accounts = await fixture.allAccounts();
      expect(accounts.length, 1);
      expect(accounts.first.name, 'Checking');

      final txns = await fixture.allTransactions();
      expect(txns.length, 1);
      expect(txns.first.amount, const Money(-100000));
      expect(txns.first.categoryId, category.id);
    });

    test('split transaction is retrievable via subTransactionsOf', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();

      final tx = await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 5),
        amount: const Money(-10000),
        isSplit: true,
        subTransactions: const [
          SubTransaction(
            id: 'sub1',
            transactionId: 'placeholder',
            amount: Money(-6000),
            deleted: false,
          ),
          SubTransaction(
            id: 'sub2',
            transactionId: 'placeholder',
            amount: Money(-4000),
            deleted: false,
          ),
        ],
      );

      final txId = tx.id;
      final subs = await fixture.subTransactionsOf(txId);
      expect(subs.length, 2);
      expect(
        subs.map((s) => s.amount.milliunits).toSet(),
        const {-6000, -4000},
      );
    });

    test('dispose closes without error', () async {
      final fixture = await BudgetFixture.create();
      // Should not throw
      await fixture.dispose();
    });
  });
}
