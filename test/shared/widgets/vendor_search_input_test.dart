import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/shared/widgets/vendor_search_input.dart';
import 'package:ledger/data/mock/mock_vendors.dart';

void main() {
  testWidgets('VendorSearchInput renders and filters mock vendors', (WidgetTester tester) async {
    MockVendor? selected;

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: VendorSearchInput(
            onVendorSelected: (v) {
              selected = v;
            },
          ),
        ),
      ),
    ));

    // Verify search input text field is rendered
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Type a matching query "Abraar"
    await tester.enterText(textField, 'Abraar');
    await tester.pumpAndSettle();

    // Verify that the suggestions list displays matching mock vendor
    final suggestion = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Abraar'),
    );
    expect(suggestion, findsOneWidget);

    // Tap on suggestion item
    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    // Verify that selection callback is called with the vendor
    expect(selected, isNotNull);
    expect(selected!.name, 'Abraar');
  });
}
