import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/repository_providers.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:budget_app/features/accounts/domain/account_repository.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:budget_app/features/budget/domain/category_budget_repository.dart';
import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';
import 'package:budget_app/features/categories/domain/category_repository.dart';
import 'package:budget_app/features/settings/domain/budget.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:budget_app/features/targets/domain/target_repository.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction_repository.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class BudgetFixture {
  BudgetFixture._({
    required this.budgetId,
    required ProviderContainer container,
    required this.accounts,
    required this.categories,
    required this.categoryBudgets,
    required this.transactions,
    required this.targets,
    required this.schedules,
  }) : _container = container;

  final String budgetId;
  final ProviderContainer _container;
  final AccountRepository accounts;
  final CategoryRepository categories;
  final CategoryBudgetRepository categoryBudgets;
  final TransactionRepository transactions;
  final TargetRepository targets;
  final ScheduledTransactionRepository schedules;

  static Future<BudgetFixture> create({String budgetId = 'test-budget'}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
      ],
    );

    final accounts = container.read(accountRepositoryProvider);
    final categories = container.read(categoryRepositoryProvider);
    final categoryBudgets = container.read(categoryBudgetRepositoryProvider);
    final txns = container.read(transactionRepositoryProvider);
    final targets = container.read(targetRepositoryProvider);
    final schedules = container.read(scheduledTransactionRepositoryProvider);
    final budgetRepo = container.read(budgetRepositoryProvider);

    await budgetRepo.save(
      Budget(
        id: budgetId,
        name: 'Test Budget',
        currencyCode: 'USD',
        currencyDecimalDigits: 2,
        dateFormat: 'MM/dd/yyyy',
      ),
    );

    return BudgetFixture._(
      budgetId: budgetId,
      container: container,
      accounts: accounts,
      categories: categories,
      categoryBudgets: categoryBudgets,
      transactions: txns,
      targets: targets,
      schedules: schedules,
    );
  }

  Future<Account> addAccount({
    String? id,
    String name = 'Checking',
    AccountType type = AccountType.checking,
    bool closed = false,
    int sortOrder = 0,
  }) async {
    final account = Account(
      id: id ?? _uuid.v4(),
      budgetId: budgetId,
      name: name,
      type: type,
      onBudget: type.isOnBudget,
      closed: closed,
      sortOrder: sortOrder,
    );
    await accounts.save(account);
    return account;
  }

  Future<CategoryGroup> addGroup({
    String? id,
    String name = 'Group',
    SystemGroupType? systemType,
    int sortOrder = 0,
  }) async {
    final group = CategoryGroup(
      id: id ?? _uuid.v4(),
      budgetId: budgetId,
      name: name,
      hidden: false,
      sortOrder: sortOrder,
      systemType: systemType,
    );
    await categories.saveGroup(group);
    return group;
  }

  Future<Category> addCategory({
    required String groupId,
    String? id,
    String name = 'Category',
    String? linkedAccountId,
    int sortOrder = 0,
  }) async {
    final category = Category(
      id: id ?? _uuid.v4(),
      groupId: groupId,
      name: name,
      hidden: false,
      sortOrder: sortOrder,
      linkedAccountId: linkedAccountId,
    );
    await categories.saveCategory(category);
    return category;
  }

  Future<CategoryBudget> assign({
    required String categoryId,
    required MonthKey month,
    required Money amount,
  }) async {
    final budget = CategoryBudget(
      id: _uuid.v4(),
      categoryId: categoryId,
      month: month,
      assigned: amount,
    );
    await categoryBudgets.save(budget);
    return budget;
  }

  Future<Target> addTarget({
    required String categoryId,
    required TargetType type,
    required Money amount,
    MonthKey? targetMonth,
  }) async {
    final target = Target(
      id: _uuid.v4(),
      categoryId: categoryId,
      type: type,
      amount: amount,
      targetMonth: targetMonth,
    );
    await targets.save(target);
    return target;
  }

  Future<Transaction> addTransaction({
    required String accountId,
    required DateTime date,
    required Money amount,
    String? id,
    String? categoryId,
    ClearedStatus cleared = ClearedStatus.uncleared,
    bool isSplit = false,
    List<SubTransaction> subTransactions = const [],
  }) async {
    final txId = id ?? _uuid.v4();
    final transaction = Transaction(
      id: txId,
      accountId: accountId,
      date: date,
      amount: amount,
      cleared: cleared,
      approved: true,
      isSplit: isSplit,
      deleted: false,
      categoryId: categoryId,
    );
    final fixedSubs =
        subTransactions.map((s) => s.copyWith(transactionId: txId)).toList();
    await transactions.save(transaction, subTransactions: fixedSubs);
    return transaction;
  }

  Future<List<Account>> allAccounts() => accounts.watchAll(budgetId).first;

  Future<List<Transaction>> allTransactions() =>
      transactions.allForBudget(budgetId);

  Future<List<SubTransaction>> subTransactionsOf(String transactionId) =>
      transactions.subTransactionsOf(transactionId);

  Future<void> dispose() async {
    _container.dispose();
  }
}
