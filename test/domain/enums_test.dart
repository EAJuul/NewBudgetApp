import 'package:budget_app/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountType.isOnBudget', () {
    test('on-budget types', () {
      expect(AccountType.checking.isOnBudget, isTrue);
      expect(AccountType.savings.isOnBudget, isTrue);
      expect(AccountType.cash.isOnBudget, isTrue);
      expect(AccountType.creditCard.isOnBudget, isTrue);
      expect(AccountType.lineOfCredit.isOnBudget, isTrue);
    });

    test('tracking types are off-budget', () {
      expect(AccountType.asset.isOnBudget, isFalse);
      expect(AccountType.liability.isOnBudget, isFalse);
    });
  });

  group('AccountType.isCreditCard', () {
    test('only creditCard is true', () {
      expect(AccountType.creditCard.isCreditCard, isTrue);
    });

    test('all other types are false', () {
      for (final t in AccountType.values) {
        if (t != AccountType.creditCard) {
          expect(t.isCreditCard, isFalse, reason: t.name);
        }
      }
    });
  });

  group('AccountType member names (Drift storage guard)', () {
    test('names match expected strings', () {
      expect(AccountType.checking.name, 'checking');
      expect(AccountType.savings.name, 'savings');
      expect(AccountType.cash.name, 'cash');
      expect(AccountType.creditCard.name, 'creditCard');
      expect(AccountType.lineOfCredit.name, 'lineOfCredit');
      expect(AccountType.asset.name, 'asset');
      expect(AccountType.liability.name, 'liability');
    });
  });

  group('ClearedStatus member names', () {
    test('names match expected strings', () {
      expect(ClearedStatus.uncleared.name, 'uncleared');
      expect(ClearedStatus.cleared.name, 'cleared');
      expect(ClearedStatus.reconciled.name, 'reconciled');
    });
  });

  group('FlagColor member names', () {
    test('names match expected strings', () {
      expect(FlagColor.red.name, 'red');
      expect(FlagColor.orange.name, 'orange');
      expect(FlagColor.yellow.name, 'yellow');
      expect(FlagColor.green.name, 'green');
      expect(FlagColor.blue.name, 'blue');
      expect(FlagColor.purple.name, 'purple');
    });
  });

  group('ScheduleFrequency member names', () {
    test('names match expected strings', () {
      expect(ScheduleFrequency.daily.name, 'daily');
      expect(ScheduleFrequency.weekly.name, 'weekly');
      expect(ScheduleFrequency.everyOtherWeek.name, 'everyOtherWeek');
      expect(ScheduleFrequency.twiceAMonth.name, 'twiceAMonth');
      expect(ScheduleFrequency.every4Weeks.name, 'every4Weeks');
      expect(ScheduleFrequency.monthly.name, 'monthly');
      expect(ScheduleFrequency.everyOtherMonth.name, 'everyOtherMonth');
      expect(ScheduleFrequency.every3Months.name, 'every3Months');
      expect(ScheduleFrequency.every6Months.name, 'every6Months');
      expect(ScheduleFrequency.yearly.name, 'yearly');
    });
  });

  group('TargetType member names', () {
    test('names match expected strings', () {
      expect(TargetType.monthlyFunding.name, 'monthlyFunding');
      expect(TargetType.targetBalance.name, 'targetBalance');
      expect(TargetType.targetBalanceByDate.name, 'targetBalanceByDate');
      expect(TargetType.monthlySpending.name, 'monthlySpending');
    });
  });

  group('SystemGroupType member names', () {
    test('names match expected strings', () {
      expect(SystemGroupType.creditCardPayments.name, 'creditCardPayments');
      expect(SystemGroupType.internal.name, 'internal');
    });
  });
}
