import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'month_budget.freezed.dart';

@freezed
abstract class CategoryBudgetLine with _$CategoryBudgetLine {
  const factory CategoryBudgetLine({
    required String categoryId,
    required Money assigned,
    required Money activity,
    required Money available,
  }) = _CategoryBudgetLine;
}

@freezed
abstract class MonthBudget with _$MonthBudget {
  const factory MonthBudget({
    required MonthKey month,
    required Money readyToAssign,
    required List<CategoryBudgetLine> lines,
  }) = _MonthBudget;

  const MonthBudget._();

  CategoryBudgetLine? lineFor(String categoryId) =>
      lines.firstWhereOrNull((l) => l.categoryId == categoryId);
}
