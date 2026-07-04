import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/bookings/screens/bookings_directory_screen.dart';
import 'package:ledger/features/bookings/widgets/vendor_booking_group.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';

void main() {
  testWidgets('BookingsDirectoryScreen renders successfully with all elements', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: BookingsDirectoryScreen(),
      ),
    ));

    // Verify Title & Header
    expect(find.text('DIRECTORY'), findsOneWidget);
    expect(find.text('Bookings by Vendor'), findsOneWidget);
    expect(find.text('Review active reservations and manage vendor schedules.'), findsOneWidget);

    // Verify FloatingSearchFAB and bottom navbar are active
    expect(find.byType(FloatingSearchFAB), findsOneWidget);

    // Verify Vendor groups render (e.g. Abraar and Ankit Singh)
    expect(find.byType(VendorBookingGroup), findsAtLeastNWidgets(2));
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));
  });

  testWidgets('BookingsDirectoryScreen filters by search text input', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: BookingsDirectoryScreen(),
      ),
    ));

    // Initially multiple vendor booking groups should exist
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));

    // Enter search text "Abraar"
    final searchInput = find.byType(TextField);
    expect(searchInput, findsOneWidget);

    await tester.enterText(searchInput, 'Abraar');
    await tester.pump();

    // Verify Ankit Singh is filtered out, and Abraar is still displayed
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsNothing);

    // Clear search query
    await tester.enterText(searchInput, '');
    await tester.pump();

    // Both should reappear
    expect(find.text('Abraar'), findsAtLeastNWidgets(1));
    expect(find.text('Ankit Singh'), findsAtLeastNWidgets(1));
  });
}
