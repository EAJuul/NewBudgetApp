import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/budgeting/account_balance_calculator.dart';
import 'package:budget_app/domain/budgeting/transfer.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

void main() {
  group('netTransferAmount', () {
    test('one inbound transfer returns its positive amount', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final receiving = await fixture.addAccount(name: 'Receiving');
      final sending = await fixture.addAccount(name: 'Sending');

      final inbound = await fixture.addTransaction(
        accountId: receiving.id,
        date: DateTime(2024, 3),
        amount: const Money(50000),
      );
      await fixture.addTransaction(
        accountId: sending.id,
        date: DateTime(2024, 3),
        amount: const Money(-50000),
      );

      final all = await fixture.allTransactions();
      final txns = all.map((t) {
        if (t.id == inbound.id) {
          return t.copyWith(
            transferTransactionId: 'other-tx',
            transferAccountId: sending.id,
          );
        }
        return t.copyWith(
          transferTransactionId: inbound.id,
          transferAccountId: receiving.id,
        );
      }).toList();

      expect(
        netTransferAmount(accountId: receiving.id, transactions: txns),
        const Money(50000),
      );
    });

    test('one outbound transfer returns its negative amount', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final sending = await fixture.addAccount(name: 'Sending');
      final receiving = await fixture.addAccount(name: 'Receiving');

      final outbound = await fixture.addTransaction(
        accountId: sending.id,
        date: DateTime(2024, 3),
        amount: const Money(-40000),
      );
      await fixture.addTransaction(
        accountId: receiving.id,
        date: DateTime(2024, 3),
        amount: const Money(40000),
      );

      final all = await fixture.allTransactions();
      final txns = all.map((t) {
        if (t.id == outbound.id) {
          return t.copyWith(
            transferTransactionId: 'other-tx',
            transferAccountId: receiving.id,
          );
        }
        return t.copyWith(
          transferTransactionId: outbound.id,
          transferAccountId: sending.id,
        );
      }).toList();

      expect(
        netTransferAmount(accountId: sending.id, transactions: txns),
        const Money(-40000),
      );
    });

    test('inbound and outbound transfers on same account sum correctly',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final acct = await fixture.addAccount(name: 'Main');
      final other = await fixture.addAccount(name: 'Other');

      // +30000 inbound, -10000 outbound → net +20000
      final txns = [
        Transaction(
          id: 'tx1',
          accountId: acct.id,
          date: DateTime(2024, 3),
          amount: const Money(30000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: false,
          transferTransactionId: 'tx2',
          transferAccountId: other.id,
        ),
        Transaction(
          id: 'tx3',
          accountId: acct.id,
          date: DateTime(2024, 3, 5),
          amount: const Money(-10000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: false,
          transferTransactionId: 'tx4',
          transferAccountId: other.id,
        ),
      ];

      expect(
        netTransferAmount(accountId: acct.id, transactions: txns),
        const Money(20000),
      );
    });

    test('deleted transfer row is excluded', () {
      final txns = [
        Transaction(
          id: 'tx1',
          accountId: 'acc1',
          date: DateTime(2024, 3),
          amount: const Money(50000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: true,
          transferTransactionId: 'tx2',
          transferAccountId: 'acc2',
        ),
      ];

      expect(
        netTransferAmount(accountId: 'acc1', transactions: txns),
        const Money.zero(),
      );
    });

    test('non-transfer transaction does not affect netTransferAmount', () {
      final txns = [
        Transaction(
          id: 'tx1',
          accountId: 'acc1',
          date: DateTime(2024, 3),
          amount: const Money(60000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: false,
          // no transferTransactionId → not a transfer
        ),
      ];

      expect(
        netTransferAmount(accountId: 'acc1', transactions: txns),
        const Money.zero(),
      );
    });
  });

  group('computeAccountBalances with transfers', () {
    test(
        'receiving account working balance increases; sending account decreases',
        () {
      const receiving = 'acc-recv';
      const sending = 'acc-send';
      final txns = [
        Transaction(
          id: 'tx1',
          accountId: receiving,
          date: DateTime(2024, 3),
          amount: const Money(80000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: false,
          transferTransactionId: 'tx2',
          transferAccountId: sending,
        ),
        Transaction(
          id: 'tx2',
          accountId: sending,
          date: DateTime(2024, 3),
          amount: const Money(-80000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: false,
          transferTransactionId: 'tx1',
          transferAccountId: receiving,
        ),
      ];

      final recvBalance =
          computeAccountBalances(accountId: receiving, transactions: txns);
      final sendBalance =
          computeAccountBalances(accountId: sending, transactions: txns);

      expect(recvBalance.working, const Money(80000));
      expect(sendBalance.working, const Money(-80000));
    });

    test('cleared transfer contributes to cleared balance', () {
      const acct = 'acc1';
      final txns = [
        Transaction(
          id: 'tx1',
          accountId: acct,
          date: DateTime(2024, 3),
          amount: const Money(50000),
          cleared: ClearedStatus.cleared,
          approved: true,
          isSplit: false,
          deleted: false,
          transferTransactionId: 'tx2',
          transferAccountId: 'acc2',
        ),
      ];

      final balances =
          computeAccountBalances(accountId: acct, transactions: txns);
      expect(balances.cleared, const Money(50000));
      expect(balances.uncleared, const Money.zero());
    });

    test('uncleared transfer does not contribute to cleared balance', () {
      const acct = 'acc1';
      final txns = [
        Transaction(
          id: 'tx1',
          accountId: acct,
          date: DateTime(2024, 3),
          amount: const Money(50000),
          cleared: ClearedStatus.uncleared,
          approved: true,
          isSplit: false,
          deleted: false,
          transferTransactionId: 'tx2',
          transferAccountId: 'acc2',
        ),
      ];

      final balances =
          computeAccountBalances(accountId: acct, transactions: txns);
      expect(balances.cleared, const Money.zero());
      expect(balances.uncleared, const Money(50000));
    });
  });
}
