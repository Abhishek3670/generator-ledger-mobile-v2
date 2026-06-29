import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/vendors/screens/vendor_directory_screen.dart';
import 'package:ledger/features/vendors/widgets/vendor_card.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';
import 'package:ledger/shared/widgets/expandable_fab_menu.dart';

void main() {
  testWidgets('VendorDirectoryScreen renders successfully with all elements', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VendorDirectoryScreen(),
    ));

    // Verify Title & Header
    expect(find.text('VENDORS'), findsOneWidget); // AppBar only (BottomNavBar consolidated to shell)
    expect(find.text('DIRECTORY'), findsOneWidget);
    expect(find.text('Vendors'), findsOneWidget);

    // Verify groups exist
    expect(find.text('Retailer Vendor'), findsOneWidget);
    expect(find.text('Rental Vendors'), findsOneWidget);

    // Verify Vendor cards render (e.g. Mallu and RS Marriage Hall)
    expect(find.byType(VendorCard), findsNWidgets(9));
    expect(find.text('Mallu'), findsOneWidget);
    expect(find.text('R S Marriage Hall'), findsOneWidget);

    // Verify ExpandableFABMenu and FloatingSearchFAB
    expect(find.byType(ExpandableFABMenu), findsOneWidget);
    expect(find.byType(FloatingSearchFAB), findsOneWidget);
  });

  testWidgets('VendorDirectoryScreen filters list using search field query', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: VendorDirectoryScreen(),
    ));

    // Initially all mock items render
    expect(find.text('Mallu'), findsOneWidget);
    expect(find.text('Panchwati Guest House'), findsOneWidget);

    // Filter using search text
    final searchInput = find.descendant(
      of: find.byType(FloatingSearchFAB),
      matching: find.byType(TextField),
    );
    expect(searchInput, findsOneWidget);

    await tester.enterText(searchInput, 'Panchwati');
    await tester.pump();

    // Verify only Panchwati matches and is displayed, Mallu is gone
    expect(find.text('Panchwati Guest House'), findsOneWidget);
    expect(find.text('Mallu'), findsNothing);
  });
}
