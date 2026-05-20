import 'package:budget_app/domain/enums.dart';

/// The next occurrence strictly after [date] for a schedule of [frequency].
/// [date] is treated as a calendar date (the time component is ignored;
/// the result has a zero time component).
DateTime advance(DateTime date, ScheduleFrequency frequency) {
  final d = DateTime(date.year, date.month, date.day);
  final raw = switch (frequency) {
    ScheduleFrequency.daily => d.add(const Duration(days: 1)),
    ScheduleFrequency.weekly => d.add(const Duration(days: 7)),
    ScheduleFrequency.everyOtherWeek => d.add(const Duration(days: 14)),
    ScheduleFrequency.every4Weeks => d.add(const Duration(days: 28)),
    ScheduleFrequency.monthly => _addMonths(d, 1),
    ScheduleFrequency.everyOtherMonth => _addMonths(d, 2),
    ScheduleFrequency.every3Months => _addMonths(d, 3),
    ScheduleFrequency.every6Months => _addMonths(d, 6),
    ScheduleFrequency.yearly => _addMonths(d, 12),
    // NEEDS REVIEW: semi-monthly anchors assumed to be 15th and 1st of next month.
    ScheduleFrequency.twiceAMonth => _advanceTwiceAMonth(d),
  };
  // Normalise to date-only to strip any DST-induced hour offset.
  return DateTime(raw.year, raw.month, raw.day);
}

DateTime _addMonths(DateTime d, int months) {
  var year = d.year;
  var month = d.month + months;
  while (month > 12) {
    month -= 12;
    year++;
  }
  final day = d.day.clamp(1, _daysInMonth(year, month));
  return DateTime(year, month, day);
}

// Returns the number of days in [month] of [year].
int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _advanceTwiceAMonth(DateTime d) {
  if (d.day < 15) return DateTime(d.year, d.month, 15);
  var month = d.month + 1;
  var year = d.year;
  if (month > 12) {
    month = 1;
    year++;
  }
  return DateTime(year, month);
}
