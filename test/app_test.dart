import 'package:budget_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BudgetApp()));
    await tester.pumpAndSettle();
    expect(find.text('NewBudgetApp — scaffold ready'), findsOneWidget);
  });
}
