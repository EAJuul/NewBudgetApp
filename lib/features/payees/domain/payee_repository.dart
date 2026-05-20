import 'package:budget_app/features/payees/domain/payee.dart';

abstract interface class PayeeRepository {
  Stream<List<Payee>> watchAll(String budgetId);
  Future<Payee?> findById(String id);
  Future<void> save(Payee payee);
  Future<void> delete(String id);
}
