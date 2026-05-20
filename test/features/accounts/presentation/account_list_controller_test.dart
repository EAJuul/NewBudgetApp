import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/data/repository_providers.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:budget_app/features/accounts/presentation/account_list_controller.dart';
import 'package:budget_app/features/settings/domain/budget.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [ProviderContainer] wired to an in-memory Drift database so the
/// controller and repository providers share the same database instance.
ProviderContainer _testContainer() {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
}

/// Subscribes to [accountListControllerProvider] (keeping it alive) and
/// returns its first non-loading value or throws on timeout.
Future<List<Account>> _firstValue(ProviderContainer container) async {
  final sub = container.listen<AsyncValue<List<Account>>>(
    accountListControllerProvider,
    (_, __) {},
  );
  addTearDown(sub.close);
  return container
      .read(accountListControllerProvider.future)
      .timeout(const Duration(seconds: 2));
}

Account _account({
  required String id,
  required String name,
  int sortOrder = 0,
  bool closed = false,
  bool onBudget = true,
  AccountType type = AccountType.checking,
}) =>
    Account(
      id: id,
      budgetId: 'budget-1',
      name: name,
      type: type,
      onBudget: onBudget,
      closed: closed,
      sortOrder: sortOrder,
    );

const _budget = Budget(
  id: 'budget-1',
  name: 'Test Budget',
  currencyCode: 'USD',
  currencyDecimalDigits: 2,
  dateFormat: 'MM/dd/yyyy',
);

void main() {
  group('AccountListController', () {
    late ProviderContainer container;

    setUp(() => container = _testContainer());
    tearDown(() => container.dispose());

    test('emits an empty list when no Budget is seeded', () async {
      final value = await _firstValue(container);
      expect(value, isEmpty);
    });

    test('emits an empty list when Budget exists but no accounts', () async {
      await container.read(budgetRepositoryProvider).save(_budget);

      final value = await _firstValue(container);
      expect(value, isEmpty);
    });

    test(
      'sorts accounts by sortOrder, then case-insensitive name',
      () async {
        await container.read(budgetRepositoryProvider).save(_budget);
        final repo = container.read(accountRepositoryProvider);
        await repo.save(_account(id: 'c', name: 'cash', sortOrder: 1));
        await repo.save(_account(id: 'a', name: 'Bravo'));
        await repo.save(_account(id: 'b', name: 'alpha'));

        final value = await _firstValue(container);
        expect(value.map((a) => a.id).toList(), <String>['b', 'a', 'c']);
      },
    );

    test('closed accounts appear in the emitted list', () async {
      await container.read(budgetRepositoryProvider).save(_budget);
      final repo = container.read(accountRepositoryProvider);
      await repo.save(_account(id: 'open', name: 'Open'));
      await repo.save(
        _account(id: 'closed', name: 'Closed', sortOrder: 1, closed: true),
      );

      final value = await _firstValue(container);
      expect(value.length, 2);
      expect(value.any((a) => a.id == 'closed'), isTrue);
    });

    test('inserting another account makes the controller emit again', () async {
      await container.read(budgetRepositoryProvider).save(_budget);
      final repo = container.read(accountRepositoryProvider);
      await repo.save(_account(id: 'first', name: 'First'));

      // Establish a subscription and capture successive snapshots.
      final emissions = <List<Account>>[];
      final sub = container.listen<AsyncValue<List<Account>>>(
        accountListControllerProvider,
        (_, next) {
          final value = next.value;
          if (value != null) emissions.add(value);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Wait until first snapshot arrives.
      await container
          .read(accountListControllerProvider.future)
          .timeout(const Duration(seconds: 2));

      await repo.save(_account(id: 'second', name: 'Second', sortOrder: 1));

      // Poll briefly until a new emission with two accounts appears.
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (DateTime.now().isBefore(deadline)) {
        if (emissions.any((e) => e.length == 2)) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        emissions.any((e) => e.length == 2),
        isTrue,
        reason: 'controller did not re-emit after second account was saved',
      );
    });
  });
}
