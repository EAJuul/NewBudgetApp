import 'dart:math';

import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/account_balance_calculator.dart';
import 'package:budget_app/domain/budgeting/budget_service.dart';
import 'package:budget_app/domain/budgeting/invariants.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/budget_fixture.dart';

BudgetService _serviceFrom(BudgetFixture fixture) => BudgetService(
      accountRepository: fixture.accounts,
      categoryRepository: fixture.categories,
      categoryBudgetRepository: fixture.categoryBudgets,
      transactionRepository: fixture.transactions,
    );

void main() {
  group('checkBudgetEquation', () {
    test('valid budget equation returns null', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      // Create: 1 account, 1 category, 1 transaction
      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id);

      // Inflow
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(100000),
      );

      // Assign to category
      await fixture.assign(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        amount: const Money(60000),
      );

      // Outflow from category
      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 15),
        amount: const Money(-50000),
        categoryId: cat.id,
      );

      // Compute month budget
      final service = _serviceFrom(fixture);
      final monthBudget = await service.computeMonth(
        fixture.budgetId,
        const MonthKey(2024, 3),
      );

      // Compute working balance
      final txns = await fixture.allTransactions();
      final balances = computeAccountBalances(
        accountId: account.id,
        transactions: txns,
      );

      final result = checkBudgetEquation(
        monthBudget: monthBudget,
        onBudgetWorkingTotal: balances.working,
      );

      expect(result, isNull);
    });

    test('broken budget equation returns error message', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat = await fixture.addCategory(groupId: group.id);

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: const Money(100000),
      );

      await fixture.assign(
        categoryId: cat.id,
        month: const MonthKey(2024, 3),
        amount: const Money(60000),
      );

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3, 15),
        amount: const Money(-50000),
        categoryId: cat.id,
      );

      final service = _serviceFrom(fixture);
      final monthBudget = await service.computeMonth(
        fixture.budgetId,
        const MonthKey(2024, 3),
      );

      // Pass wrong working total (off by 1)
      const wrongTotal = Money(12345);

      final result = checkBudgetEquation(
        monthBudget: monthBudget,
        onBudgetWorkingTotal: wrongTotal,
      );

      expect(result, isNotNull);
      expect(result, contains('Budget equation failed'));
    });
  });

  group('checkSplitSum', () {
    test('valid split sum returns null', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat1 = await fixture.addCategory(groupId: group.id);
      final cat2 = await fixture.addCategory(groupId: group.id);

      const sub1Amount = Money(30000);
      const sub2Amount = Money(20000);
      const parentAmount = Money(50000);

      final sub1 = SubTransaction(
        id: 'sub1',
        transactionId: 'parent-tx',
        amount: sub1Amount,
        deleted: false,
        categoryId: cat1.id,
      );

      final sub2 = SubTransaction(
        id: 'sub2',
        transactionId: 'parent-tx',
        amount: sub2Amount,
        deleted: false,
        categoryId: cat2.id,
      );

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: parentAmount,
        isSplit: true,
        subTransactions: [sub1, sub2],
      );

      final parent = await fixture.allTransactions();
      expect(parent, hasLength(1));

      final subs = await fixture.subTransactionsOf(parent[0].id);

      final result = checkSplitSum(
        parent: parent[0],
        subTransactions: subs,
      );

      expect(result, isNull);
    });

    test('broken split sum returns error message', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account = await fixture.addAccount();
      final group = await fixture.addGroup();
      final cat1 = await fixture.addCategory(groupId: group.id);
      final cat2 = await fixture.addCategory(groupId: group.id);

      const sub1Amount = Money(30000);
      const sub2Amount = Money(20000);
      const parentAmount = Money(100000); // Doesn't match subs sum

      final sub1 = SubTransaction(
        id: 'sub1',
        transactionId: 'parent-tx',
        amount: sub1Amount,
        deleted: false,
        categoryId: cat1.id,
      );

      final sub2 = SubTransaction(
        id: 'sub2',
        transactionId: 'parent-tx',
        amount: sub2Amount,
        deleted: false,
        categoryId: cat2.id,
      );

      await fixture.addTransaction(
        accountId: account.id,
        date: DateTime(2024, 3),
        amount: parentAmount,
        isSplit: true,
        subTransactions: [sub1, sub2],
      );

      final parent = await fixture.allTransactions();
      expect(parent, hasLength(1));

      final subs = await fixture.subTransactionsOf(parent[0].id);

      final result = checkSplitSum(
        parent: parent[0],
        subTransactions: subs,
      );

      expect(result, isNotNull);
      expect(result, contains('Split sum failed'));
    });
  });

  group('checkTransferPair', () {
    test('valid transfer pair returns null', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account1 = await fixture.addAccount();
      final account2 = await fixture.addAccount(name: 'Savings');

      const amount = Money(50000);

      // Create transfer from account1 to account2
      final tx1 = await fixture.addTransaction(
        accountId: account1.id,
        date: DateTime(2024, 3),
        amount: -amount, // outflow from account1
      );

      final tx2 = await fixture.addTransaction(
        accountId: account2.id,
        date: DateTime(2024, 3),
        amount: amount, // inflow to account2
      );

      // Update to link them
      final tx1Updated = tx1.copyWith(
        transferTransactionId: tx2.id,
        transferAccountId: account2.id,
      );
      final tx2Updated = tx2.copyWith(
        transferTransactionId: tx1.id,
        transferAccountId: account1.id,
      );

      await fixture.transactions.save(tx1Updated);
      await fixture.transactions.save(tx2Updated);

      final result = checkTransferPair(tx1Updated, tx2Updated);

      expect(result, isNull);
    });

    test('broken transfer pair (amounts mismatch) returns error', () async {
      final fixture = await BudgetFixture.create();
      addTearDown(fixture.dispose);

      final account1 = await fixture.addAccount();
      final account2 = await fixture.addAccount(name: 'Savings');

      // Amounts don't match
      final tx1 = await fixture.addTransaction(
        accountId: account1.id,
        date: DateTime(2024, 3),
        amount: const Money(-50000),
      );

      final tx2 = await fixture.addTransaction(
        accountId: account2.id,
        date: DateTime(2024, 3),
        amount: const Money(30000), // Wrong amount
      );

      final tx1Updated = tx1.copyWith(
        transferTransactionId: tx2.id,
        transferAccountId: account2.id,
      );
      final tx2Updated = tx2.copyWith(
        transferTransactionId: tx1.id,
        transferAccountId: account1.id,
      );

      final result = checkTransferPair(tx1Updated, tx2Updated);

      expect(result, isNotNull);
      expect(result, contains('Transfer pair failed'));
    });
  });

  group('Budget equation property-based test', () {
    test('checkBudgetEquation holds for random budgets (50 iterations)',
        () async {
      const iterations = 50;
      final rng = Random(42); // Fixed seed for reproducibility

      for (var i = 0; i < iterations; i++) {
        final fixture = await BudgetFixture.create();
        addTearDown(fixture.dispose);

        // Add 1-3 checking accounts
        final accountCount = 1 + rng.nextInt(3);
        final accounts = <String>[];
        for (var a = 0; a < accountCount; a++) {
          final acc = await fixture.addAccount(
            name: 'Account$a',
          );
          accounts.add(acc.id);
        }

        // Add 1-2 groups with 1-3 categories each
        final groupCount = 1 + rng.nextInt(2);
        final categories = <String>[];
        for (var g = 0; g < groupCount; g++) {
          final group = await fixture.addGroup(name: 'Group$g');
          final catCount = 1 + rng.nextInt(3);
          for (var c = 0; c < catCount; c++) {
            final cat = await fixture.addCategory(
              groupId: group.id,
              name: 'Cat$c',
            );
            categories.add(cat.id);
          }
        }

        // Generate random inflows (no category) and outflows (with category)
        final txCount = 2 + rng.nextInt(5);

        for (var t = 0; t < txCount; t++) {
          final accountId = accounts[rng.nextInt(accounts.length)];
          final isInflow = rng.nextBool();

          if (isInflow) {
            // Inflow: random amount 1000-50000, no category
            final amount = Money(1000 + rng.nextInt(50000));
            await fixture.addTransaction(
              accountId: accountId,
              date: DateTime(2024, 3, 1 + rng.nextInt(28)),
              amount: amount,
            );
          } else {
            // Outflow: random amount 100-30000, with category
            final amount = Money(-(100 + rng.nextInt(30000)));
            final catId = categories[rng.nextInt(categories.length)];
            await fixture.addTransaction(
              accountId: accountId,
              date: DateTime(2024, 3, 1 + rng.nextInt(28)),
              amount: amount,
              categoryId: catId,
            );
          }
        }

        // Random assignments to categories
        for (final catId in categories) {
          if (rng.nextBool()) {
            final amount = Money(100 + rng.nextInt(50000));
            await fixture.assign(
              categoryId: catId,
              month: const MonthKey(2024, 3),
              amount: amount,
            );
          }
        }

        // Compute month budget
        final service = _serviceFrom(fixture);
        final monthBudget = await service.computeMonth(
          fixture.budgetId,
          const MonthKey(2024, 3),
        );

        // Compute on-budget working total
        final allTxns = await fixture.allTransactions();
        var onBudgetTotal = const Money.zero();
        for (final acc in accounts) {
          final balances = computeAccountBalances(
            accountId: acc,
            transactions: allTxns,
          );
          onBudgetTotal = onBudgetTotal + balances.working;
        }

        // Assert invariant holds
        final result = checkBudgetEquation(
          monthBudget: monthBudget,
          onBudgetWorkingTotal: onBudgetTotal,
        );

        expect(
          result,
          isNull,
          reason: 'Iteration $i: Budget equation should hold. '
              'monthBudget: ${monthBudget.lines.length} lines, '
              'RTA=${monthBudget.readyToAssign.milliunits}, '
              'onBudgetTotal=${onBudgetTotal.milliunits}',
        );
      }
    });
  });
}
