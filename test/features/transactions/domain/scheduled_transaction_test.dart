import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/transactions/domain/scheduled_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledTransaction', () {
    test('constructs with all fields', () {
      final schedule = ScheduledTransaction(
        id: 's1',
        accountId: 'a1',
        amount: Money(-50000),
        frequency: ScheduleFrequency.monthly,
        nextDate: DateTime(2024, 4, 1),
        payeeId: 'p1',
        categoryId: 'cat1',
        memo: 'Monthly rent',
      );
      expect(schedule.id, 's1');
      expect(schedule.accountId, 'a1');
      expect(schedule.amount, Money(-50000));
      expect(schedule.payeeId, 'p1');
      expect(schedule.categoryId, 'cat1');
      expect(schedule.memo, 'Monthly rent');
      expect(schedule.frequency, ScheduleFrequency.monthly);
      expect(schedule.nextDate, DateTime(2024, 4, 1));
    });

    test('copyWith(nextDate: ...) updates only that field', () {
      final s = ScheduledTransaction(
        id: 's1',
        accountId: 'a1',
        amount: Money(10000),
        frequency: ScheduleFrequency.weekly,
        nextDate: DateTime(2024, 3, 1),
      );
      final updated = s.copyWith(nextDate: DateTime(2024, 3, 8));
      expect(updated.id, 's1');
      expect(updated.nextDate, DateTime(2024, 3, 8));
      expect(updated.frequency, ScheduleFrequency.weekly);
    });

    test('equality and hashCode as value object', () {
      final s1 = ScheduledTransaction(
        id: 's1',
        accountId: 'a1',
        amount: Money(10000),
        frequency: ScheduleFrequency.monthly,
        nextDate: DateTime(2024, 4, 1),
      );
      final s2 = ScheduledTransaction(
        id: 's1',
        accountId: 'a1',
        amount: Money(10000),
        frequency: ScheduleFrequency.monthly,
        nextDate: DateTime(2024, 4, 1),
      );
      expect(s1, equals(s2));
      expect(s1.hashCode, s2.hashCode);
    });
  });
}
