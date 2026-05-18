import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String groupId,
    required String name,
    required bool hidden,
    required int sortOrder,
    String? note,
    String? linkedAccountId,
  }) = _Category;

  const Category._();

  bool get isCreditCardPayment => linkedAccountId != null;
}
