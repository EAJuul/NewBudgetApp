import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';

/// Available balance per month.
///
/// available(m) = carryover(m-1) + assigned(m) + activity(m)
/// Starting carryover is zero.
///
/// When [creditOverspentFor] is null (simple mode), negative carryover rolls
/// forward unchanged. When supplied, cash overspending is dropped (absorbed by
/// RTA) and only the credit portion rolls forward:
/// carryover(m) = max(available(m), −creditOverspentFor(m))
Map<MonthKey, Money> computeCategoryAvailableSeries({
  required List<MonthKey> months,
  required Money Function(MonthKey month) assignedFor,
  required Money Function(MonthKey month) activityFor,
  Money Function(MonthKey month)? creditOverspentFor,
}) {
  final result = <MonthKey, Money>{};
  var carryover = const Money.zero();
  for (final month in months) {
    final available = carryover + assignedFor(month) + activityFor(month);
    result[month] = available;
    if (creditOverspentFor == null || !available.isNegative) {
      carryover = available;
    } else {
      final negCredit = -creditOverspentFor(month);
      carryover = available > negCredit ? available : negCredit;
    }
  }
  return result;
}
