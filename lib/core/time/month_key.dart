import 'package:meta/meta.dart';

/// A budget month, e.g. 2026-05. Immutable.
@immutable
class MonthKey implements Comparable<MonthKey> {
  const MonthKey(this.year, this.month)
      : assert(month >= 1 && month <= 12, 'month must be in 1..12');

  factory MonthKey.fromDate(DateTime date) => MonthKey(date.year, date.month);

  /// Parses a 'YYYY-MM' string. Throws [FormatException] on invalid input.
  factory MonthKey.parse(String yyyyMm) {
    // Require exactly 'YYYY-MM' format: 7 chars, dash at index 4.
    if (yyyyMm.length != 7 || yyyyMm[4] != '-') {
      throw FormatException('Invalid MonthKey format', yyyyMm);
    }
    final year = int.tryParse(yyyyMm.substring(0, 4));
    final month = int.tryParse(yyyyMm.substring(5));
    if (year == null || month == null || month < 1 || month > 12) {
      throw FormatException('Invalid MonthKey format', yyyyMm);
    }
    return MonthKey(year, month);
  }

  final int year;
  final int month;

  int get _ordinal => year * 12 + (month - 1);

  MonthKey next() => addMonths(1);
  MonthKey previous() => addMonths(-1);

  MonthKey addMonths(int count) {
    final ord = _ordinal + count;
    return MonthKey(ord ~/ 12, ord % 12 + 1);
  }

  /// Signed number of months from this to [other].
  int monthsUntil(MonthKey other) => other._ordinal - _ordinal;

  /// Whether [date] falls within this calendar month.
  bool contains(DateTime date) => date.year == year && date.month == month;

  String toIso() => '$year-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is MonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  int compareTo(MonthKey other) => _ordinal.compareTo(other._ordinal);

  @override
  String toString() => toIso();
}
