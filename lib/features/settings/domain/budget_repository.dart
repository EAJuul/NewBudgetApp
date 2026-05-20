import 'package:budget_app/features/settings/domain/budget.dart';

abstract interface class BudgetRepository {
  Future<Budget?> getPrimary();
  Stream<Budget?> watchPrimary();
  Future<void> save(Budget budget);
}
