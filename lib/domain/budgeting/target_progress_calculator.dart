import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'target_progress_calculator.freezed.dart';

@freezed
abstract class TargetProgress with _$TargetProgress {
  const factory TargetProgress({
    required Money needed,
    required bool isMet,
  }) = _TargetProgress;
}

/// Progress of [target] for [month], given the category's [assigned] and
/// [available] amounts for that month (from M2-T03 / M2-T04 / the budget line).
TargetProgress computeTargetProgress({
  required Target target,
  required MonthKey month,
  required Money assigned,
  required Money available,
}) {
  return switch (target.type) {
    TargetType.monthlyFunding => _fromAssigned(target.amount, assigned),
    TargetType.monthlySpending => _fromAvailable(target.amount, available),
    TargetType.targetBalance => _fromAvailable(target.amount, available),
    TargetType.targetBalanceByDate => _byDate(
        target.amount,
        available,
        month,
        target.targetMonth!,
      ),
  };
}

TargetProgress _fromAssigned(Money target, Money assigned) {
  final isMet = assigned >= target;
  return TargetProgress(
    isMet: isMet,
    needed: isMet ? const Money.zero() : target - assigned,
  );
}

TargetProgress _fromAvailable(Money target, Money available) {
  final isMet = available >= target;
  return TargetProgress(
    isMet: isMet,
    needed: isMet ? const Money.zero() : target - available,
  );
}

TargetProgress _byDate(
  Money target,
  Money available,
  MonthKey month,
  MonthKey targetMonth,
) {
  final remaining = target - available;
  if (remaining <= const Money.zero()) {
    return const TargetProgress(needed: Money.zero(), isMet: true);
  }
  final monthsLeft = month.monthsUntil(targetMonth).clamp(1, 999999);
  return TargetProgress(
    needed: Money(_ceilDiv(remaining.milliunits, monthsLeft)),
    isMet: false,
  );
}

int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;
