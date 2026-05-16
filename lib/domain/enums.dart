enum AccountType {
  checking,
  savings,
  cash,
  creditCard,
  lineOfCredit,
  asset,
  liability;

  bool get isOnBudget => switch (this) {
        AccountType.asset || AccountType.liability => false,
        _ => true,
      };

  bool get isCreditCard => this == AccountType.creditCard;
}

enum ClearedStatus { uncleared, cleared, reconciled }

enum FlagColor { red, orange, yellow, green, blue, purple }

enum ScheduleFrequency {
  daily,
  weekly,
  everyOtherWeek,
  twiceAMonth,
  every4Weeks,
  monthly,
  everyOtherMonth,
  every3Months,
  every6Months,
  yearly,
}

enum TargetType {
  monthlyFunding,
  targetBalance,
  targetBalanceByDate,
  monthlySpending,
}

enum SystemGroupType { creditCardPayments, internal }
