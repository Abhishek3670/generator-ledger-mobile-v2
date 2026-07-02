import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/vendors/widgets/edit_vendor_modal.dart';
import 'package:ledger/shared/models/vendor.dart';

void main() {
  testWidgets('EditVendorModal renders successfully', (WidgetTester tester) async {
    const testVendor = Vendor(
      id: 'VEN-TEST',
      name: 'Test Vendor',
      location: 'New York',
      phone: '1234567890',
      category: 'rental',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditVendorModal(
          vendor: testVendor,
          onClose: () {},
          onSave: (_) {},
        ),
      ),
    ));

    expect(find.text('EDIT VENDOR'), findsOneWidget);
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('LOCATION'), findsOneWidget);
    expect(find.text('PHONE'), findsOneWidget);
  });
}
