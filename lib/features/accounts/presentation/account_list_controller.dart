import 'package:budget_app/data/repository_providers.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_list_controller.g.dart';

/// Streams every account of the primary budget, sorted by `sortOrder` then
/// `name` (case-insensitive). Closed accounts are included — the screen layer
/// (M3-T11) decides how to group them.
///
/// When no `Budget` exists yet (pre-onboarding) the stream emits an empty list
/// rather than an error so the UI can render an empty / onboarding state.
@riverpod
class AccountListController extends _$AccountListController {
  @override
  Stream<List<Account>> build() async* {
    final budget = await ref.watch(budgetRepositoryProvider).getPrimary();
    if (budget == null) {
      yield const <Account>[];
      return;
    }
    final accountRepo = ref.watch(accountRepositoryProvider);
    yield* accountRepo.watchAll(budget.id).map((accounts) {
      return [...accounts]..sort(_bySortOrderThenName);
    });
  }
}

int _bySortOrderThenName(Account a, Account b) {
  final byOrder = a.sortOrder.compareTo(b.sortOrder);
  if (byOrder != 0) return byOrder;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
