import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_budget.freezed.dart';

@freezed
abstract class CategoryBudget with _$CategoryBudget {
  const factory CategoryBudget({
    required String id,
    required String categoryId,
    required MonthKey month,
    required Money assigned,
  }) = _CategoryBudget;
}
