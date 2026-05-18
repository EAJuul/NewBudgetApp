import 'package:budget_app/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    required String budgetId,
    required String name,
    required AccountType type,
    required bool onBudget,
    required bool closed,
    required int sortOrder,
    String? note,
  }) = _Account;
}
