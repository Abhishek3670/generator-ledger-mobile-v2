import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/admin/screens/integrations_screen.dart';

void main() {
  testWidgets('IntegrationsScreen renders successfully with placeholder content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: IntegrationsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify illustrative icon
    expect(find.byIcon(Icons.construction), findsOneWidget);

    // Verify "Coming Soon" header
    expect(find.text('Coming Soon'), findsOneWidget);

    // Verify description
    expect(find.textContaining('under development'), findsOneWidget);
  });
}
