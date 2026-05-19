import 'package:budget_app/features/targets/domain/target.dart';

abstract interface class TargetRepository {
  Stream<List<Target>> watchAll();
  Future<Target?> findForCategory(String categoryId);
  Future<void> save(Target target);
  Future<void> deleteForCategory(String categoryId);
}
