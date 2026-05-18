import 'package:budget_app/data/database/connection.dart';
import 'package:budget_app/data/database/tables/accounts_table.dart';
import 'package:budget_app/data/database/tables/budgets_table.dart';
import 'package:budget_app/data/database/tables/categories_table.dart';
import 'package:budget_app/data/database/tables/category_budgets_table.dart';
import 'package:budget_app/data/database/tables/category_groups_table.dart';
import 'package:budget_app/data/database/tables/payees_table.dart';
import 'package:budget_app/data/database/tables/scheduled_transactions_table.dart';
import 'package:budget_app/data/database/tables/settings_table.dart';
import 'package:budget_app/data/database/tables/sub_transactions_table.dart';
import 'package:budget_app/data/database/tables/targets_table.dart';
import 'package:budget_app/data/database/tables/transactions_table.dart';
import 'package:budget_app/domain/enums.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Budgets,
    Accounts,
    CategoryGroups,
    Categories,
    CategoryBudgets,
    Targets,
    Payees,
    Settings,
    Transactions,
    SubTransactions,
    ScheduledTransactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
