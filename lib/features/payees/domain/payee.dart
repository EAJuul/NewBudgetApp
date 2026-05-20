import 'package:freezed_annotation/freezed_annotation.dart';

part 'payee.freezed.dart';

@freezed
abstract class Payee with _$Payee {
  const factory Payee({
    required String id,
    required String budgetId,
    required String name,
    String? defaultCategoryId,
    String? transferAccountId,
  }) = _Payee;

  const Payee._();

  bool get isTransferPayee => transferAccountId != null;
}
