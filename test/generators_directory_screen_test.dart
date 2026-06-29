import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/generators/screens/generators_directory_screen.dart';
import 'package:ledger/features/generators/widgets/inventory_group_section.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';
import 'package:ledger/shared/widgets/expandable_fab_menu.dart';

void main() {
  testWidgets('GeneratorsDirectoryScreen renders successfully with all elements', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GeneratorsDirectoryScreen(),
    ));

    // Verify Title & Header
    expect(find.text('FLEET'), findsOneWidget);
    expect(find.text('DIRECTORY'), findsOneWidget);
    expect(find.text('Generators'), findsOneWidget);

    // Verify Booked Date Card
    expect(find.text('BOOKED DATE'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Verify Inventory sections
    expect(find.byType(InventoryGroupSection), findsNWidgets(3));
    expect(find.text('Retailer Genset'), findsOneWidget);
    expect(find.text('Permanent Genset'), findsOneWidget);
    expect(find.text('Emergency Genset'), findsOneWidget);

    // Verify ExpandableFABMenu and FloatingSearchFAB
    expect(find.byType(ExpandableFABMenu), findsOneWidget);
    expect(find.byType(FloatingSearchFAB), findsOneWidget);
  });

  testWidgets('GeneratorsDirectoryScreen filters list using search field query', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GeneratorsDirectoryScreen(),
    ));

    // Initially all mock items render
    expect(find.text('GEN-100KVA-02'), findsOneWidget);
    expect(find.text('GEN-45KVA-HA-11'), findsOneWidget);

    // Filter using search text
    final searchInput = find.descendant(
      of: find.byType(FloatingSearchFAB),
      matching: find.byType(TextField),
    );
    expect(searchInput, findsOneWidget);

    await tester.enterText(searchInput, 'GEN-45KVA');
    await tester.pump();

    // Verify only the permanent genset matching is displayed, and others are gone
    expect(find.text('GEN-45KVA-HA-11'), findsOneWidget);
    expect(find.text('GEN-100KVA-02'), findsNothing);
  });
}
