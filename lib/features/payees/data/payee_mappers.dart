import 'package:budget_app/data/database/app_database.dart';
import 'package:budget_app/features/payees/domain/payee.dart';
import 'package:drift/drift.dart';

Payee payeeFromRow(PayeeRow row) => Payee(
      id: row.id,
      budgetId: row.budgetId,
      name: row.name,
      defaultCategoryId: row.defaultCategoryId,
      transferAccountId: row.transferAccountId,
    );

PayeesCompanion payeeToCompanion(Payee payee) => PayeesCompanion(
      id: Value(payee.id),
      budgetId: Value(payee.budgetId),
      name: Value(payee.name),
      defaultCategoryId: Value(payee.defaultCategoryId),
      transferAccountId: Value(payee.transferAccountId),
    );
