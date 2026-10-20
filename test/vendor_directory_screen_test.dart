import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/vendor_provider.dart';
import 'package:ledger/data/mock/mock_vendors.dart';
import 'package:ledger/data/repositories/vendor_repository.dart';
import 'package:ledger/features/vendors/screens/vendor_directory_screen.dart';
import 'package:ledger/features/vendors/widgets/vendor_card.dart';
import 'package:ledger/features/vendors/widgets/vendor_group_section.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';
import 'package:ledger/shared/widgets/expandable_fab_menu.dart';

void main() {
  testWidgets('VendorDirectoryScreen renders successfully with all elements', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: VendorDirectoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('DIRECTORY'), findsOneWidget);
    expect(find.text('Vendors'), findsOneWidget);

    // Verify groups exist
    expect(find.text('Retailer Vendor'), findsOneWidget);
    expect(find.text('Rental Vendor'), findsOneWidget);

    // Verify VendorGroupSection widgets render
    expect(find.byType(VendorGroupSection), findsNWidgets(2));

    // Verify Vendor cards render (e.g. Mallu and RS Marriage Hall)
    expect(find.byType(VendorCard), findsNWidgets(9));
    expect(find.text('Mallu'), findsOneWidget);
    expect(find.text('R S Marriage Hall'), findsOneWidget);

    // Verify ExpandableFABMenu and FloatingSearchFAB
    expect(find.byType(ExpandableFABMenu), findsOneWidget);
    expect(find.byType(FloatingSearchFAB), findsOneWidget);
  });

  testWidgets('VendorDirectoryScreen filters list using search field query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: VendorDirectoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

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

  testWidgets('Tapping a vendor card opens VendorDetailModal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_FakeVendorRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: VendorDirectoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the first vendor card (Abraar)
    await tester.tap(find.text('Abraar'));
    await tester.pumpAndSettle();

    // Verify VendorDetailModal appears with vendor name
    // The DraggableFormSheet should show the vendor's name as title
    expect(find.text('VENDOR ID'), findsOneWidget);
    expect(find.text('VEN011'), findsWidgets);
    expect(find.text('CATEGORY'), findsOneWidget);
  });

  testWidgets(
    'VendorGroupSection renders title row with ellipsis without overflow on narrow width',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250,
              child: VendorGroupSection(
                title: 'Very Long Retailer Vendor Category Name That Should Ellipsize',
                description: 'Test description',
                category: 'retailer',
                vendors: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final textFinder = find.text('Very Long Retailer Vendor Category Name That Should Ellipsize');
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, equals(1));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    },
  );

  testWidgets(
    'VendorGroupSection handles extreme system font scaling (2.5x) without overflow',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.5),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 320,
              child: VendorGroupSection(
                title: 'Retailer Vendor',
                description: 'Test description',
                category: 'retailer',
                vendors: [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeVendorRepository extends VendorRepository {
  @override
  Future<List<MockVendor>> getVendors() async => List.of(mockVendors);

  @override
  Future<MockVendor> createVendor(MockVendor vendor) async => vendor;

  @override
  Future<MockVendor> updateVendor(String id, MockVendor vendor) async => vendor;

  @override
  Future<void> deleteVendor(String id) async {}
}
