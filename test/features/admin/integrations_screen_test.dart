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

    // Verify Header and title
    expect(find.text('Booking Reminders'), findsOneWidget);
    expect(find.text('INTEGRATIONS / SETTINGS'), findsOneWidget);

    // Verify master switch card
    expect(find.text('Enable Booking Reminders'), findsOneWidget);
  });
}
