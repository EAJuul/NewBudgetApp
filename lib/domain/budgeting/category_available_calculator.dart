import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';

/// Available balance per month under simple rollover.
///
/// available(m) = available(m-1) + assigned(m) + activity(m)
/// Starting balance before the first month is zero.
/// Negative carryover rolls forward unchanged.
Map<MonthKey, Money> computeCategoryAvailableSeries({
  required List<MonthKey> months,
  required Money Function(MonthKey month) assignedFor,
  required Money Function(MonthKey month) activityFor,
}) {
  final result = <MonthKey, Money>{};
  var running = Money.zero();
  for (final month in months) {
    running = running + assignedFor(month) + activityFor(month);
    result[month] = running;
  }
  return result;
}
