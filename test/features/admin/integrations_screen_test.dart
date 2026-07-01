import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/admin/screens/integrations_screen.dart';

void main() {
  testWidgets('IntegrationsScreen renders successfully with placeholder content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IntegrationsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('INTEGRATIONS'), findsOneWidget);

    // Verify illustrative icon
    expect(find.byIcon(Icons.construction), findsOneWidget);

    // Verify "Coming Soon" header
    expect(find.text('Coming Soon'), findsOneWidget);

    // Verify description
    expect(find.textContaining('under development'), findsOneWidget);
  });
}
