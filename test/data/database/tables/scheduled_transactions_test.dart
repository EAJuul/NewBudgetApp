import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/budgets_table.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/category_groups_table.dart';
import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:budget_app/data/database/tables/scheduled_transactions_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

part 'scheduled_transactions_test.g.dart';

@DriftDatabase(
  tables: [
    ScheduledTransactions,
    Accounts,
    Budgets,
    Categories,
    CategoryGroups,
    Payees,
  ],
)
class _TestDb extends _$_TestDb {
  _TestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

void main() {
  group('ScheduledTransactions table', () {
    late _TestDb db;

    setUp(() => db = _TestDb());

    tearDown(() => db.close());

    test('frequency and nextDate round-trip for monthly', () async {
      const id = 'scheduled-1';
      const accountId = 'account-1';
      const amount = 50000; // $50.00
      const frequency = ScheduleFrequency.monthly;
      const nextDate = '2026-06-01';
      const createdAt = '2026-05-18T00:00:00Z';
      const updatedAt = '2026-05-18T00:00:00Z';

      await db.into(db.scheduledTransactions).insert(
            ScheduledTransactionsCompanion.insert(
              id: id,
              accountId: accountId,
              amount: amount,
              frequency: frequency,
              nextDate: nextDate,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      final row = await (db.select(db.scheduledTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.frequency, ScheduleFrequency.monthly);
      expect(row.nextDate, nextDate);
    });

    test('frequency round-trips for different schedule types', () async {
      const accountId = 'account-1';
      const amount = 25000; // $25.00
      const createdAt = '2026-05-18T00:00:00Z';
      const updatedAt = '2026-05-18T00:00:00Z';

      const id1 = 'scheduled-2';
      await db.into(db.scheduledTransactions).insert(
            ScheduledTransactionsCompanion.insert(
              id: id1,
              accountId: accountId,
              amount: amount,
              frequency: ScheduleFrequency.everyOtherWeek,
              nextDate: '2026-05-25',
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      const id2 = 'scheduled-3';
      await db.into(db.scheduledTransactions).insert(
            ScheduledTransactionsCompanion.insert(
              id: id2,
              accountId: accountId,
              amount: amount,
              frequency: ScheduleFrequency.yearly,
              nextDate: '2027-05-18',
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      final row1 = await (db.select(db.scheduledTransactions)
            ..where((t) => t.id.equals(id1)))
          .getSingle();
      expect(row1.frequency, ScheduleFrequency.everyOtherWeek);

      final row2 = await (db.select(db.scheduledTransactions)
            ..where((t) => t.id.equals(id2)))
          .getSingle();
      expect(row2.frequency, ScheduleFrequency.yearly);
    });

    test('nullable payeeId and categoryId round-trip as null', () async {
      const id = 'scheduled-4';
      const accountId = 'account-1';
      const amount = 75000; // $75.00
      const frequency = ScheduleFrequency.weekly;
      const nextDate = '2026-05-25';
      const createdAt = '2026-05-18T00:00:00Z';
      const updatedAt = '2026-05-18T00:00:00Z';

      await db.into(db.scheduledTransactions).insert(
            ScheduledTransactionsCompanion.insert(
              id: id,
              accountId: accountId,
              amount: amount,
              frequency: frequency,
              nextDate: nextDate,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      final row = await (db.select(db.scheduledTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.payeeId, null);
      expect(row.categoryId, null);
    });

    test('negative amount round-trips', () async {
      const id = 'scheduled-5';
      const accountId = 'account-1';
      const amount = -50000; // -$50.00
      const frequency = ScheduleFrequency.monthly;
      const nextDate = '2026-06-01';
      const createdAt = '2026-05-18T00:00:00Z';
      const updatedAt = '2026-05-18T00:00:00Z';

      await db.into(db.scheduledTransactions).insert(
            ScheduledTransactionsCompanion.insert(
              id: id,
              accountId: accountId,
              amount: amount,
              frequency: frequency,
              nextDate: nextDate,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );

      final row = await (db.select(db.scheduledTransactions)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.amount, amount);
    });
  });
}
