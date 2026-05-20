import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/budgeting/account_balance_calculator.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

void main() {
  group('computeAccountBalances', () {
    test('no transactions → all balances are zero', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final txns = await fixture.allTransactions();
      final result = computeAccountBalances(
        accountId: account.id,
        transactions: txns,
      );

      expect(result.working, const Money.zero());
      expect(result.cleared, const Money.zero());
      expect(result.uncleared, const Money.zero());
    });

    test('mixed uncleared and cleared transactions', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      // uncleared: +50000
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(50000),
      );
      // cleared: -20000
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 2),
        amount: const Money(-20000),
        cleared: ClearedStatus.cleared,
      );

      final txns = await fixture.allTransactions();
      final result = computeAccountBalances(
        accountId: account.id,
        transactions: txns,
      );

      // working = 50000 + (-20000) = 30000
      expect(result.working, const Money(30000));
      // cleared = -20000
      expect(result.cleared, const Money(-20000));
      // uncleared = 30000 - (-20000) = 50000
      expect(result.uncleared, const Money(50000));
    });

    test('reconciled transaction counts toward cleared balance', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(100000),
        cleared: ClearedStatus.reconciled,
      );

      final txns = await fixture.allTransactions();
      final result = computeAccountBalances(
        accountId: account.id,
        transactions: txns,
      );

      expect(result.working, const Money(100000));
      expect(result.cleared, const Money(100000));
      expect(result.uncleared, const Money.zero());
    });

    test('deleted transaction is excluded from all balances', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(10000),
      );
      final toDelete = await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 2),
        amount: const Money(99999),
      );
      await fixture.transactions.softDelete(toDelete.id);

      final txns = await fixture.allTransactions();
      // allForBudget excludes soft-deleted rows
      // But computeAccountBalances also filters deleted=true
      // Pass raw transactions including deleted one to test the filter
      final deletedTx = toDelete.copyWith(deleted: true);
      final allTxns = [...txns, deletedTx];

      final result = computeAccountBalances(
        accountId: account.id,
        transactions: allTxns,
      );

      expect(result.working, const Money(10000)); // only the non-deleted one
    });

    test('transactions for a different account are excluded', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account1 = await fixture.addAccount();
      final account2 = await fixture.addAccount(name: 'Savings');

      await fixture.addTransaction(
        accountId: account1.id,
        date: DateTime(2024, 3),
        amount: const Money(30000),
      );
      await fixture.addTransaction(
        accountId: account2.id,
        date: DateTime(2024, 3),
        amount: const Money(99999),
      );

      final txns = await fixture.allTransactions();
      final result = computeAccountBalances(
        accountId: account1.id,
        transactions: txns,
      );

      expect(result.working, const Money(30000));
    });

    test('negative working balance (outflows > inflows)', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(-75000),
        cleared: ClearedStatus.cleared,
      );
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 2),
        amount: const Money(20000),
      );

      final txns = await fixture.allTransactions();
      final result = computeAccountBalances(
        accountId: account.id,
        transactions: txns,
      );

      // working = -75000 + 20000 = -55000
      expect(result.working, const Money(-55000));
      // cleared = -75000
      expect(result.cleared, const Money(-75000));
      // uncleared = -55000 - (-75000) = 20000
      expect(result.uncleared, const Money(20000));
    });
  });
}
