import 'package:budget_app/features/accounts/presentation/account_list_controller.dart';
import 'package:budget_app/features/accounts/presentation/widgets/account_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The flat account list screen. Grouped presentation (Budget / Tracking /
/// Closed) is a separate widget delivered by M3-T11.
class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/accounts/new'),
        tooltip: 'Add account',
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load accounts: $error'),
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No accounts yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = accounts[i];
              return AccountListItem(
                account: a,
                onTap: () => context.go('/accounts/${a.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
