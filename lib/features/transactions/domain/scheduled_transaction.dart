import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scheduled_transaction.freezed.dart';

@freezed
abstract class ScheduledTransaction with _$ScheduledTransaction {
  const factory ScheduledTransaction({
    required String id,
    required String accountId,
    required Money amount,
    required ScheduleFrequency frequency,
    required DateTime nextDate,
    String? payeeId,
    String? categoryId,
    String? memo,
  }) = _ScheduledTransaction;
}
