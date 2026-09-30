import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/vendors/widgets/vendor_card.dart';
import 'package:ledger/shared/models/vendor.dart';

void main() {
  testWidgets('VendorCard renders vendor details', (WidgetTester tester) async {
    const vendor = Vendor(
      id: 'VEN-001',
      name: 'Test Vendor',
      location: '123 Test St',
      phone: '1234567890',
      category: 'rental',
    );

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: VendorCard(vendor: vendor),
      ),
    ));

    expect(find.text('Test Vendor'), findsOneWidget);
    expect(find.text('VEN-001'), findsOneWidget);
    expect(find.text('123 Test St'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
  });

  testWidgets('VendorCard handles long text and does not crash', (WidgetTester tester) async {
    const longVendor = Vendor(
      id: 'VEN-VERY-LONG-ID-THAT-COULD-OVERFLOW-THE-CONTAINER-WIDTH',
      name: 'Very Long Vendor Name That Will Definitely Overflow The Row Layout If Not Ellipsized Properly',
      location: 'Very Long Address Location That Can Span Multiple Columns And Typically Overflow Horizontal Space',
      phone: '1234567890',
      category: 'rental',
    );

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: VendorCard(vendor: longVendor),
      ),
    ));

    expect(find.text(longVendor.name), findsOneWidget);
    expect(find.text(longVendor.id), findsOneWidget);
    expect(find.text(longVendor.location), findsOneWidget);
  });
}
