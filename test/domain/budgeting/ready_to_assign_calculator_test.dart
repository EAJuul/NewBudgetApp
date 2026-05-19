import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/ready_to_assign_calculator.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

// Helper to make a minimal Transaction for pure-function tests
Transaction _makeTx({
  required String id,
  required String accountId,
  required Money amount,
  bool deleted = false,
  bool isSplit = false,
  String? transferTransactionId,
  String? categoryId,
}) =>
    Transaction(
      id: id,
      accountId: accountId,
      date: DateTime(2024, 3, 1),
      amount: amount,
      cleared: ClearedStatus.uncleared,
      approved: true,
      isSplit: isSplit,
      deleted: deleted,
      transferTransactionId: transferTransactionId,
      categoryId: categoryId,
    );

Account _makeAccount({
  required String id,
  required String budgetId,
  AccountType type = AccountType.checking,
}) =>
    Account(
      id: id,
      budgetId: budgetId,
      name: 'Account',
      type: type,
      onBudget: type.isOnBudget,
      closed: false,
      sortOrder: 0,
    );

void main() {
  group('computeReadyToAssign', () {
    test('single on-budget inflow with no assignments → RTA equals inflow',
        () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount(name: 'Checking');
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 1),
        amount: Money(100000),
        // No categoryId → inflow to RTA
      );

      final accts = await fixture.allAccounts();
      final txns = await fixture.allTransactions();

      final rta = computeReadyToAssign(
        accounts: accts,
        transactions: txns,
        categoryBudgets: [],
      );

      expect(rta, Money(100000));
    });

    test('assigning money reduces RTA by assigned total', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 1),
        amount: Money(100000),
      );
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id);
      final cb = await fixture.assign(
        categoryId: cat.id,
        month: MonthKey(2024, 3),
        amount: Money(30000),
      );

      final accts = await fixture.allAccounts();
      final txns = await fixture.allTransactions();

      final rta = computeReadyToAssign(
        accounts: accts,
        transactions: txns,
        categoryBudgets: [cb],
      );

      expect(rta, Money(70000)); // 100000 - 30000
    });

    test('assigning more than inflow yields negative RTA', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 1),
        amount: Money(50000),
      );
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id);
      final cb = await fixture.assign(
        categoryId: cat.id,
        month: MonthKey(2024, 3),
        amount: Money(80000),
      );

      final accts = await fixture.allAccounts();
      final txns = await fixture.allTransactions();

      final rta = computeReadyToAssign(
        accounts: accts,
        transactions: txns,
        categoryBudgets: [cb],
      );

      expect(rta, Money(-30000)); // 50000 - 80000
    });

    test('inflow on off-budget account does not affect RTA', () {
      final account = _makeAccount(
        id: 'a1',
        budgetId: 'b1',
        type: AccountType.asset, // off-budget
      );
      final tx = _makeTx(id: 'tx1', accountId: 'a1', amount: Money(999999));

      final rta = computeReadyToAssign(
        accounts: [account],
        transactions: [tx],
        categoryBudgets: [],
      );

      expect(rta, Money.zero());
    });

    test('deleted inflow is excluded', () {
      final account = _makeAccount(id: 'a1', budgetId: 'b1');
      final tx = _makeTx(
        id: 'tx1',
        accountId: 'a1',
        amount: Money(100000),
        deleted: true,
      );

      final rta = computeReadyToAssign(
        accounts: [account],
        transactions: [tx],
        categoryBudgets: [],
      );

      expect(rta, Money.zero());
    });

    test('categorised transaction is not counted as RTA inflow', () {
      final account = _makeAccount(id: 'a1', budgetId: 'b1');
      final tx = _makeTx(
        id: 'tx1',
        accountId: 'a1',
        amount: Money(100000),
        categoryId: 'cat1', // categorised → not RTA inflow
      );

      final rta = computeReadyToAssign(
        accounts: [account],
        transactions: [tx],
        categoryBudgets: [],
      );

      expect(rta, Money.zero());
    });

    test('transfer transaction is not counted as RTA inflow', () {
      final account = _makeAccount(id: 'a1', budgetId: 'b1');
      final tx = _makeTx(
        id: 'tx1',
        accountId: 'a1',
        amount: Money(100000),
        transferTransactionId: 'tx2', // is a transfer
      );

      final rta = computeReadyToAssign(
        accounts: [account],
        transactions: [tx],
        categoryBudgets: [],
      );

      expect(rta, Money.zero());
    });
  });
}
