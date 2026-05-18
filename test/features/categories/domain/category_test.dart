import 'package:budget_app/features/categories/domain/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    test('isCreditCardPayment is false when linkedAccountId is null', () {
      const category = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      expect(category.isCreditCardPayment, isFalse);
    });

    test('isCreditCardPayment is true when linkedAccountId is set', () {
      const category = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Credit Card Payment',
        hidden: false,
        sortOrder: 0,
        linkedAccountId: 'acc-abc',
      );

      expect(category.isCreditCardPayment, isTrue);
    });

    test('copyWith returns new instance with updated field', () {
      const originalCategory = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      final hiddenCategory = originalCategory.copyWith(hidden: true);

      expect(hiddenCategory.hidden, isTrue);
      expect(originalCategory.hidden, isFalse);
      expect(hiddenCategory, isNot(originalCategory));
    });

    test('equality is based on all fields', () {
      const category1 = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      const category2 = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      const category3 = Category(
        id: 'cat-2',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      expect(category1, equals(category2));
      expect(category1.hashCode, equals(category2.hashCode));
      expect(category1, isNot(category3));
    });
  });
}
