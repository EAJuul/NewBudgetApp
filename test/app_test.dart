import 'package:budget_app/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders', (tester) async {
    await tester.pumpWidget(const BudgetApp());
    expect(find.text('NewBudgetApp — scaffold ready'), findsOneWidget);
  });
}
