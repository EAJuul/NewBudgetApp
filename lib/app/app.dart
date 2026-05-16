import 'package:flutter/material.dart';

/// Root widget of NewBudgetApp.
///
/// Placeholder shell created during scaffolding. Task M0-T05 replaces the
/// `home` argument with a `go_router` configuration. See docs/02-architecture.md.
class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewBudgetApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
      ),
      home: const Scaffold(
        body: Center(child: Text('NewBudgetApp — scaffold ready')),
      ),
    );
  }
}
