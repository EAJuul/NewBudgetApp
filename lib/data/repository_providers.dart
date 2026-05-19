import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/accounts/data/account_repository_impl.dart';
import 'package:budget_app/features/accounts/domain/account_repository.dart';
import 'package:budget_app/features/budget/data/category_budget_repository_impl.dart';
import 'package:budget_app/features/budget/domain/category_budget_repository.dart';
import 'package:budget_app/features/categories/data/category_repository_impl.dart';
import 'package:budget_app/features/categories/domain/category_repository.dart';
import 'package:budget_app/features/payees/data/payee_repository_impl.dart';
import 'package:budget_app/features/payees/domain/payee_repository.dart';
import 'package:budget_app/features/settings/data/budget_repository_impl.dart';
import 'package:budget_app/features/settings/data/settings_store_impl.dart';
import 'package:budget_app/features/settings/domain/budget_repository.dart';
import 'package:budget_app/features/settings/domain/settings_store.dart';
import 'package:budget_app/features/targets/data/target_repository_impl.dart';
import 'package:budget_app/features/targets/domain/target_repository.dart';
import 'package:budget_app/features/transactions/data/scheduled_transaction_repository_impl.dart';
import 'package:budget_app/features/transactions/data/transaction_repository_impl.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction_repository.dart';
import 'package:budget_app/features/transactions/domain/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_providers.g.dart';

@riverpod
AccountRepository accountRepository(Ref ref) =>
    AccountRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
CategoryRepository categoryRepository(Ref ref) =>
    CategoryRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
CategoryBudgetRepository categoryBudgetRepository(Ref ref) =>
    CategoryBudgetRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
TransactionRepository transactionRepository(Ref ref) =>
    TransactionRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
PayeeRepository payeeRepository(Ref ref) =>
    PayeeRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
TargetRepository targetRepository(Ref ref) =>
    TargetRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
ScheduledTransactionRepository scheduledTransactionRepository(Ref ref) =>
    ScheduledTransactionRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
BudgetRepository budgetRepository(Ref ref) =>
    BudgetRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
SettingsStore settingsStore(Ref ref) =>
    SettingsStoreImpl(ref.watch(appDatabaseProvider));
