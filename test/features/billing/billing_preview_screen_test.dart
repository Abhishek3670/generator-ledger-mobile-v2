import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/billing/screens/billing_preview_screen.dart';

void main() {
  testWidgets('BillingPreviewScreen renders sticky header and bottom grand total', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: BillingPreviewScreen()),
      ),
    ));

    // Verify fixed top header exists with back button
    expect(find.text('BACK TO DASHBOARD'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // Verify billing title
    expect(find.text('BILLING'), findsOneWidget);
    expect(find.text('Billing Preview'), findsOneWidget);

    // Grand total starts out showing when the page loads with mock vendor data
    await tester.pumpAndSettle();

    // Verify grand total exists at the bottom
    expect(find.text('GRAND TOTAL'), findsOneWidget);
  });
}
