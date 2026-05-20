import 'package:budget_app/data/daos/payees_dao.dart';
import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/payees/data/payee_mappers.dart';
import 'package:budget_app/features/payees/domain/payee.dart';
import 'package:budget_app/features/payees/domain/payee_repository.dart';

class PayeeRepositoryImpl implements PayeeRepository {
  PayeeRepositoryImpl(AppDatabase db) : _dao = PayeesDao(db);

  final PayeesDao _dao;

  @override
  Stream<List<Payee>> watchAll(String budgetId) => _dao
      .watchByBudget(budgetId)
      .map((rows) => rows.map(payeeFromRow).toList());

  @override
  Future<Payee?> findById(String id) async {
    final row = await _dao.findById(id);
    return row == null ? null : payeeFromRow(row);
  }

  @override
  Future<void> save(Payee payee) => _dao.upsert(payeeToCompanion(payee));

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}
