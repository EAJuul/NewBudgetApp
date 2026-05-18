import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryGroup', () {
    test('isSystem is false when systemType is null', () {
      const group = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      expect(group.isSystem, isFalse);
    });

    test('isSystem is true when systemType is creditCardPayments', () {
      const group = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Credit Card Payments',
        hidden: false,
        sortOrder: 0,
        systemType: SystemGroupType.creditCardPayments,
      );

      expect(group.isSystem, isTrue);
    });

    test('copyWith returns new instance with updated field', () {
      const originalGroup = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Original Name',
        hidden: false,
        sortOrder: 0,
      );

      final renamedGroup = originalGroup.copyWith(name: 'Renamed');

      expect(renamedGroup.name, equals('Renamed'));
      expect(originalGroup.name, equals('Original Name'));
      expect(renamedGroup, isNot(originalGroup));
    });

    test('equality is based on all fields', () {
      const group1 = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      const group2 = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      const group3 = CategoryGroup(
        id: 'group-2',
        budgetId: 'budget-1',
        name: 'Groceries',
        hidden: false,
        sortOrder: 0,
      );

      expect(group1, equals(group2));
      expect(group1.hashCode, equals(group2.hashCode));
      expect(group1, isNot(group3));
    });
  });
}
