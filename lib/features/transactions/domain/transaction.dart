import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String accountId,
    required DateTime date,
    required Money amount,
    required ClearedStatus cleared,
    required bool approved,
    required bool isSplit,
    required bool deleted,
    String? payeeId,
    String? categoryId,
    String? memo,
    FlagColor? flagColor,
    String? transferTransactionId,
    String? transferAccountId,
    String? scheduledTransactionId,
    String? importId,
  }) = _Transaction;

  const Transaction._();

  bool get isTransfer => transferTransactionId != null;
}
