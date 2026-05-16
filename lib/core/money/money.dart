import 'package:meta/meta.dart';

/// An amount of money in integer *milliunits* (1 unit = 1000 milliunits).
/// Immutable. Money is never represented with `double`.
@immutable
class Money implements Comparable<Money> {
  const Money(this.milliunits);
  const Money.zero() : milliunits = 0;

  /// Builds from whole units + optional sub-unit milliunits.
  /// [units] and [milliunits] must not have conflicting signs.
  factory Money.of(int units, [int milliunits = 0]) {
    assert(
      units == 0 || milliunits == 0 || units.sign == milliunits.sign,
      'units and milliunits must not have conflicting signs',
    );
    return Money(units * 1000 + milliunits);
  }

  final int milliunits;

  Money operator +(Money other) => Money(milliunits + other.milliunits);
  Money operator -(Money other) => Money(milliunits - other.milliunits);
  Money operator -() => Money(-milliunits);
  Money operator *(int factor) => Money(milliunits * factor);

  bool operator <(Money other) => milliunits < other.milliunits;
  bool operator <=(Money other) => milliunits <= other.milliunits;
  bool operator >(Money other) => milliunits > other.milliunits;
  bool operator >=(Money other) => milliunits >= other.milliunits;

  bool get isZero => milliunits == 0;
  bool get isNegative => milliunits < 0;
  bool get isPositive => milliunits > 0;

  Money abs() => milliunits < 0 ? Money(-milliunits) : this;

  @override
  bool operator ==(Object other) =>
      other is Money && other.milliunits == milliunits;

  @override
  int get hashCode => milliunits.hashCode;

  @override
  int compareTo(Money other) => milliunits.compareTo(other.milliunits);

  @override
  String toString() => 'Money($milliunits)';
}
