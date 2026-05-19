import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:budget_app/features/categories/data/category_mappers.dart';
import 'package:budget_app/features/categories/domain/category.dart';
import 'package:budget_app/features/categories/domain/category_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('categoryGroupFromRow', () {
    test('maps all fields with non-null systemType', () {
      const row = CategoryGroupRow(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Expenses',
        hidden: false,
        sortOrder: 0,
        systemType: SystemGroupType.creditCardPayments,
      );

      final entity = categoryGroupFromRow(row);

      expect(entity.id, 'group-1');
      expect(entity.budgetId, 'budget-1');
      expect(entity.name, 'Expenses');
      expect(entity.hidden, false);
      expect(entity.sortOrder, 0);
      expect(entity.systemType, SystemGroupType.creditCardPayments);
      expect(entity.isSystem, isTrue);
    });

    test('maps all fields with null systemType', () {
      const row = CategoryGroupRow(
        id: 'group-2',
        budgetId: 'budget-1',
        name: 'Income',
        hidden: true,
        sortOrder: 1,
      );

      final entity = categoryGroupFromRow(row);

      expect(entity.id, 'group-2');
      expect(entity.budgetId, 'budget-1');
      expect(entity.name, 'Income');
      expect(entity.hidden, true);
      expect(entity.sortOrder, 1);
      expect(entity.systemType, isNull);
      expect(entity.isSystem, isFalse);
    });
  });

  group('categoryGroupToCompanion', () {
    test('wraps all fields in Value()', () {
      const group = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Expenses',
        hidden: false,
        sortOrder: 0,
        systemType: SystemGroupType.internal,
      );

      final companion = categoryGroupToCompanion(group);

      expect(companion.id.present, isTrue);
      expect(companion.id.value, 'group-1');
      expect(companion.budgetId.present, isTrue);
      expect(companion.budgetId.value, 'budget-1');
      expect(companion.name.present, isTrue);
      expect(companion.name.value, 'Expenses');
      expect(companion.hidden.present, isTrue);
      expect(companion.hidden.value, false);
      expect(companion.sortOrder.present, isTrue);
      expect(companion.sortOrder.value, 0);
      expect(companion.systemType.present, isTrue);
      expect(companion.systemType.value, SystemGroupType.internal);
    });

    test('handles null systemType', () {
      const group = CategoryGroup(
        id: 'group-1',
        budgetId: 'budget-1',
        name: 'Savings',
        hidden: false,
        sortOrder: 2,
      );

      final companion = categoryGroupToCompanion(group);

      expect(companion.systemType.present, isTrue);
      expect(companion.systemType.value, isNull);
    });
  });

  group('categoryFromRow', () {
    test('maps all fields with non-null linkedAccountId', () {
      const row = CategoryRow(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Groceries',
        hidden: false,
        note: 'Food and drinks',
        sortOrder: 0,
        linkedAccountId: 'acc-1',
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      );

      final entity = categoryFromRow(row);

      expect(entity.id, 'cat-1');
      expect(entity.groupId, 'group-1');
      expect(entity.name, 'Groceries');
      expect(entity.hidden, false);
      expect(entity.note, 'Food and drinks');
      expect(entity.sortOrder, 0);
      expect(entity.linkedAccountId, 'acc-1');
      expect(entity.isCreditCardPayment, isTrue);
    });

    test('maps all fields with null linkedAccountId and null note', () {
      const row = CategoryRow(
        id: 'cat-2',
        groupId: 'group-1',
        name: 'Utilities',
        hidden: true,
        sortOrder: 1,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      );

      final entity = categoryFromRow(row);

      expect(entity.id, 'cat-2');
      expect(entity.groupId, 'group-1');
      expect(entity.name, 'Utilities');
      expect(entity.hidden, true);
      expect(entity.note, isNull);
      expect(entity.sortOrder, 1);
      expect(entity.linkedAccountId, isNull);
      expect(entity.isCreditCardPayment, isFalse);
    });
  });

  group('categoryToCompanion', () {
    test('wraps all fields in Value() with timestamps', () {
      const category = Category(
        id: 'cat-1',
        groupId: 'group-1',
        name: 'Rent',
        hidden: false,
        note: 'Monthly rent',
        sortOrder: 0,
      );

      final companion = categoryToCompanion(
        category,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-02T00:00:00Z',
      );

      expect(companion.id.present, isTrue);
      expect(companion.id.value, 'cat-1');
      expect(companion.groupId.present, isTrue);
      expect(companion.groupId.value, 'group-1');
      expect(companion.name.present, isTrue);
      expect(companion.name.value, 'Rent');
      expect(companion.hidden.present, isTrue);
      expect(companion.hidden.value, false);
      expect(companion.note.present, isTrue);
      expect(companion.note.value, 'Monthly rent');
      expect(companion.sortOrder.present, isTrue);
      expect(companion.sortOrder.value, 0);
      expect(companion.linkedAccountId.present, isTrue);
      expect(companion.linkedAccountId.value, isNull);
      expect(companion.createdAt.present, isTrue);
      expect(companion.createdAt.value, '2026-01-01T00:00:00Z');
      expect(companion.updatedAt.present, isTrue);
      expect(companion.updatedAt.value, '2026-01-02T00:00:00Z');
    });

    test('roundtrip with null note and linkedAccountId', () {
      const category = Category(
        id: 'cat-2',
        groupId: 'group-1',
        name: 'Transport',
        hidden: false,
        sortOrder: 2,
      );

      final companion = categoryToCompanion(
        category,
        createdAt: '2026-01-01T00:00:00Z',
        updatedAt: '2026-01-01T00:00:00Z',
      );

      expect(companion.note.present, isTrue);
      expect(companion.note.value, isNull);
      expect(companion.linkedAccountId.present, isTrue);
      expect(companion.linkedAccountId.value, isNull);
    });
  });
}
