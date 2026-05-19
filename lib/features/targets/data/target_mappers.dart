import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/core/time/month_key.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:drift/drift.dart';

Target targetFromRow(TargetRow row) => Target(
      id: row.id,
      categoryId: row.categoryId,
      type: row.type,
      amount: Money(row.amount),
      targetMonth:
          row.targetMonth == null ? null : MonthKey.parse(row.targetMonth!),
    );

TargetsCompanion targetToCompanion(
  Target target, {
  required String createdAt,
  required String updatedAt,
}) =>
    TargetsCompanion(
      id: Value(target.id),
      categoryId: Value(target.categoryId),
      type: Value(target.type),
      amount: Value(target.amount.milliunits),
      targetMonth: Value(target.targetMonth?.toIso()),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
