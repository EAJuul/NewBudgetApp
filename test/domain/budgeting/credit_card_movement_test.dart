import 'package:budget_app/core/money/money.dart';
import 'package:budget_app/domain/budgeting/credit_card_movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('creditCardPaymentMovement', () {
    test('purchase fully funded: movement equals full spend', () {
      // category has 100, spend is 60 → movement = +60
      final movement = creditCardPaymentMovement(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money(100000),
      );
      expect(movement, const Money(60000));
    });

    test('purchase partially funded: movement equals funded portion', () {
      // category has 40, spend is 60 → movement = +40
      final movement = creditCardPaymentMovement(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money(40000),
      );
      expect(movement, const Money(40000));
    });

    test('purchase unfunded: movement is zero', () {
      // category has 0 or negative → movement = 0
      final movementZero = creditCardPaymentMovement(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money.zero(),
      );
      expect(movementZero, const Money.zero());

      final movementNegative = creditCardPaymentMovement(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money(-10000),
      );
      expect(movementNegative, const Money.zero());
    });

    test('refund: movement is negative (full reversal — NEEDS REVIEW)', () {
      // refund of 30 → movement = -30
      final movement = creditCardPaymentMovement(
        transactionAmount: const Money(30000),
        categoryAvailableBeforeTransaction: const Money(50000),
      );
      expect(movement, const Money(-30000));
    });

    test('zero transaction amount yields zero movement', () {
      final movement = creditCardPaymentMovement(
        transactionAmount: const Money.zero(),
        categoryAvailableBeforeTransaction: const Money(50000),
      );
      expect(movement, const Money.zero());
    });
  });

  group('creditOverspendingPortion', () {
    test('purchase fully funded: overspending portion is zero', () {
      final portion = creditOverspendingPortion(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money(100000),
      );
      expect(portion, const Money.zero());
    });

    test('purchase partially funded: overspending portion equals remainder', () {
      // category has 40, spend is 60 → overspend = 20
      final portion = creditOverspendingPortion(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money(40000),
      );
      expect(portion, const Money(20000));
    });

    test('purchase unfunded: overspending portion equals whole spend', () {
      final portion = creditOverspendingPortion(
        transactionAmount: const Money(-60000),
        categoryAvailableBeforeTransaction: const Money.zero(),
      );
      expect(portion, const Money(60000));
    });

    test('refund: overspending portion is zero', () {
      final portion = creditOverspendingPortion(
        transactionAmount: const Money(30000),
        categoryAvailableBeforeTransaction: const Money(50000),
      );
      expect(portion, const Money.zero());
    });

    test('zero transaction amount yields zero overspending portion', () {
      final portion = creditOverspendingPortion(
        transactionAmount: const Money.zero(),
        categoryAvailableBeforeTransaction: const Money(50000),
      );
      expect(portion, const Money.zero());
    });
  });
}
