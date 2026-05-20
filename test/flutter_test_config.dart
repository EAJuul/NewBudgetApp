import 'dart:async';

import 'package:drift/drift.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Each test creates its own NativeDatabase.memory() — a separate executor —
  // so Drift's multi-instance warning is a false positive in this test suite.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
