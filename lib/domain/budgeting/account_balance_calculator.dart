import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/transactions/domain/transaction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_balance_calculator.freezed.dart';

@freezed
abstract class AccountBalances with _$AccountBalances {
  const factory AccountBalances({
    required Money working,
    required Money cleared,
    required Money uncleared,
  }) = _AccountBalances;
}

AccountBalances computeAccountBalances({
  required String accountId,
  required Iterable<Transaction> transactions,
}) {
  var working = Money.zero();
  var cleared = Money.zero();

  for (final tx in transactions) {
    if (tx.accountId != accountId || tx.deleted) continue;
    working = working + tx.amount;
    if (tx.cleared == ClearedStatus.cleared ||
        tx.cleared == ClearedStatus.reconciled) {
      cleared = cleared + tx.amount;
    }
  }

  return AccountBalances(
    working: working,
    cleared: cleared,
    uncleared: working - cleared,
  );
}
