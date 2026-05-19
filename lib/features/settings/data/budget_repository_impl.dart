import 'package:budget_app/data/daos/budgets_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/settings/data/budget_mappers.dart';
import 'package:budget_app/features/settings/domain/budget.dart';
import 'package:budget_app/features/settings/domain/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(AppDatabase db) : _dao = BudgetsDao(db);

  final BudgetsDao _dao;

  @override
  Future<Budget?> getPrimary() async {
    final row = await _dao.findFirst();
    return row == null ? null : budgetFromRow(row);
  }

  @override
  Stream<Budget?> watchPrimary() =>
      _dao.watchFirst().map((row) => row == null ? null : budgetFromRow(row));

  @override
  Future<void> save(Budget budget) async {
    final existing = await _dao.findFirst();
    final now = DateTime.now().toUtc().toIso8601String();
    final createdAt = existing?.createdAt ?? now;
    await _dao.upsert(
      budgetToCompanion(budget, createdAt: createdAt, updatedAt: now),
    );
  }
}
