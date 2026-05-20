import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'target.freezed.dart';

@freezed
abstract class Target with _$Target {
  const factory Target({
    required String id,
    required String categoryId,
    required TargetType type,
    required Money amount,
    MonthKey? targetMonth,
  }) = _Target;
}
