import 'package:budget_app/domain/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_group.freezed.dart';

@freezed
abstract class CategoryGroup with _$CategoryGroup {
  const factory CategoryGroup({
    required String id,
    required String budgetId,
    required String name,
    required bool hidden,
    required int sortOrder,
    SystemGroupType? systemType,
  }) = _CategoryGroup;

  const CategoryGroup._();

  bool get isSystem => systemType != null;
}
