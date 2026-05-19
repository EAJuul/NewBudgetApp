import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/repository_providers.dart';
import 'package:budget_app/features/accounts/domain/account_repository.dart';
import 'package:budget_app/features/budget/domain/category_budget_repository.dart';
import 'package:budget_app/features/categories/domain/category_repository.dart';
import 'package:budget_app/features/payees/domain/payee_repository.dart';
import 'package:budget_app/features/settings/domain/budget_repository.dart';
import 'package:budget_app/features/settings/domain/settings_store.dart';
import 'package:budget_app/features/targets/domain/target_repository.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction_repository.dart';
import 'package:budget_app/features/transactions/domain/transaction_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _createContainer() {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith(
        (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
      ),
    ],
  );
  return container;
}

void main() {
  test(
      'all nine providers resolve to non-null instances of their interface types',
      () {
    final container = _createContainer();
    addTearDown(container.dispose);

    expect(container.read(accountRepositoryProvider), isA<AccountRepository>());
    expect(
      container.read(categoryRepositoryProvider),
      isA<CategoryRepository>(),
    );
    expect(
      container.read(categoryBudgetRepositoryProvider),
      isA<CategoryBudgetRepository>(),
    );
    expect(
      container.read(transactionRepositoryProvider),
      isA<TransactionRepository>(),
    );
    expect(container.read(payeeRepositoryProvider), isA<PayeeRepository>());
    expect(container.read(targetRepositoryProvider), isA<TargetRepository>());
    expect(
      container.read(scheduledTransactionRepositoryProvider),
      isA<ScheduledTransactionRepository>(),
    );
    expect(container.read(budgetRepositoryProvider), isA<BudgetRepository>());
    expect(container.read(settingsStoreProvider), isA<SettingsStore>());
  });

  test('reading the same provider twice returns the identical instance', () {
    final container = _createContainer();
    addTearDown(container.dispose);

    final r1 = container.read(accountRepositoryProvider);
    final r2 = container.read(accountRepositoryProvider);
    expect(identical(r1, r2), isTrue);
  });
}
