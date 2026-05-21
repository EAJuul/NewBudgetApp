import 'package:budget_app/core/money/currency_formatter.dart';
import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/data/repository_providers.dart';
import 'package:budget_app/domain/budgeting/account_balance_calculator.dart';
import 'package:budget_app/features/accounts/domain/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_list_item.g.dart';

/// The working balance of [accountId]; re-emits whenever its transactions
/// change. Family-scoped so each list row owns an independent subscription.
@riverpod
Stream<Money> accountWorkingBalance(Ref ref, String accountId) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  return txRepo.watchByAccount(accountId).map((txns) {
    return computeAccountBalances(
      accountId: accountId,
      transactions: txns,
    ).working;
  });
}

/// A single account row: name on the left, working balance on the right.
class AccountListItem extends ConsumerWidget {
  const AccountListItem({required this.account, this.onTap, super.key});

  final Account account;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(accountWorkingBalanceProvider(account.id));
    final theme = Theme.of(context);
    final isClosed = account.closed;
    return ListTile(
      title: Text(account.name),
      subtitle: isClosed
          ? Text(
              'Closed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          : null,
      trailing: balance.when(
        data: (m) => Text(
          CurrencyFormatter.format(m),
          style: theme.textTheme.titleMedium?.copyWith(
            color: m.isNegative ? theme.colorScheme.error : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        loading: () => const Text('—'),
        error: (_, __) =>
            Icon(Icons.error_outline, color: theme.colorScheme.error),
      ),
      onTap: onTap,
    );
  }
}
