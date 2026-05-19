import 'package:budget_app/data/daos/targets_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/targets/data/target_mappers.dart';
import 'package:budget_app/features/targets/domain/target.dart';
import 'package:budget_app/features/targets/domain/target_repository.dart';

class TargetRepositoryImpl implements TargetRepository {
  TargetRepositoryImpl(AppDatabase db) : _dao = TargetsDao(db);

  final TargetsDao _dao;

  @override
  Stream<List<Target>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(targetFromRow).toList());

  @override
  Future<Target?> findForCategory(String categoryId) async {
    final row = await _dao.findByCategory(categoryId);
    return row == null ? null : targetFromRow(row);
  }

  @override
  Future<void> save(Target target) async {
    final existing = await _dao.findByCategory(target.categoryId);
    final now = DateTime.now().toUtc().toIso8601String();
    final id = existing?.id ?? target.id;
    final createdAt = existing?.createdAt ?? now;
    await _dao.upsert(
      targetToCompanion(
        target.copyWith(id: id),
        createdAt: createdAt,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> deleteForCategory(String categoryId) =>
      _dao.deleteByCategory(categoryId);
}
