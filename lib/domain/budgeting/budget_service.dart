import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/budgeting/category_activity_calculator.dart';
import 'package:budget_app/domain/budgeting/category_available_calculator.dart';
import 'package:budget_app/domain/budgeting/month_budget.dart';
import 'package:budget_app/domain/budgeting/ready_to_assign_calculator.dart';
import 'package:budget_app/features/accounts/domain/account_repository.dart';
import 'package:budget_app/features/budget/domain/category_budget.dart';
import 'package:budget_app/features/budget/domain/category_budget_repository.dart';
import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_repository.dart';
import 'package:budget_app/features/transactions/domain/sub_transaction.dart';
import 'package:budget_app/features/transactions/domain/transaction_repository.dart';

class BudgetService {
  BudgetService({
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required CategoryBudgetRepository categoryBudgetRepository,
    required TransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _categoryRepository = categoryRepository,
        _categoryBudgetRepository = categoryBudgetRepository,
        _transactionRepository = transactionRepository;

  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final CategoryBudgetRepository _categoryBudgetRepository;
  final TransactionRepository _transactionRepository;

  Future<MonthBudget> computeMonth(String budgetId, MonthKey month) async {
    // 1. Load accounts
    final accounts = await _accountRepository.watchAll(budgetId).first;

    // 2. Load categories (flatten from groups)
    final groups = await _categoryRepository.watchAllGroups(budgetId).first;
    final categories = <Category>[];
    for (final group in groups) {
      final cats =
          await _categoryRepository.watchCategoriesInGroup(group.id).first;
      categories.addAll(cats);
    }

    // 3. Load transactions + sub-transactions for splits
    final transactions = await _transactionRepository.allForBudget(budgetId);
    final allSubTransactions = <SubTransaction>[];
    for (final tx in transactions) {
      if (tx.isSplit) {
        final subs = await _transactionRepository.subTransactionsOf(tx.id);
        allSubTransactions.addAll(subs);
      }
    }

    // 4. Load assignments per category
    final allCategoryBudgets = <CategoryBudget>[];
    final assignmentsByCategory = <String, List<CategoryBudget>>{};
    for (final cat in categories) {
      final budgets =
          await _categoryBudgetRepository.watchForCategory(cat.id).first;
      assignmentsByCategory[cat.id] = budgets;
      allCategoryBudgets.addAll(budgets);
    }

    // 5. Build month range: from earliest data month to requested month
    var startMonth = month;
    for (final cb in allCategoryBudgets) {
      if (cb.month.compareTo(startMonth) < 0) startMonth = cb.month;
    }
    for (final tx in transactions) {
      final txMonth = MonthKey.fromDate(tx.date);
      if (txMonth.compareTo(startMonth) < 0) startMonth = txMonth;
    }

    final months = <MonthKey>[];
    var current = startMonth;
    while (current.compareTo(month) <= 0) {
      months.add(current);
      current = current.next();
    }

    // 6. Per category: compute CategoryBudgetLine
    final lines = <CategoryBudgetLine>[];
    for (final cat in categories) {
      final catAssignments = assignmentsByCategory[cat.id] ?? [];
      final assignmentMap = {
        for (final cb in catAssignments) cb.month: cb.assigned,
      };

      final availableSeries = computeCategoryAvailableSeries(
        months: months,
        assignedFor: (m) => assignmentMap[m] ?? const Money.zero(),
        activityFor: (m) => computeCategoryActivity(
          categoryId: cat.id,
          month: m,
          transactions: transactions,
          subTransactions: allSubTransactions,
        ),
      );

      lines.add(
        CategoryBudgetLine(
          categoryId: cat.id,
          assigned: assignmentMap[month] ?? const Money.zero(),
          activity: computeCategoryActivity(
            categoryId: cat.id,
            month: month,
            transactions: transactions,
            subTransactions: allSubTransactions,
          ),
          available: availableSeries[month] ?? const Money.zero(),
        ),
      );
    }

    // 7. Ready to Assign
    final rta = computeReadyToAssign(
      accounts: accounts,
      transactions: transactions,
      categoryBudgets: allCategoryBudgets,
    );

    return MonthBudget(
      month: month,
      readyToAssign: rta,
      lines: lines,
    );
  }
}
