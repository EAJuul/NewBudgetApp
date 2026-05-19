import 'package:budget_app/core/money/money.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sub_transaction.freezed.dart';

@freezed
abstract class SubTransaction with _$SubTransaction {
  const factory SubTransaction({
    required String id,
    required String transactionId,
    required Money amount,
    required bool deleted,
    String? categoryId,
    String? payeeId,
    String? memo,
  }) = _SubTransaction;
}
