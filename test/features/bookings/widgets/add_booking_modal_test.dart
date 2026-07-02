import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/bookings/widgets/add_booking_modal.dart';

void main() {
  testWidgets('AddBookingModal renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddBookingModal(
          onClose: () {},
          onSave: (_) {},
        ),
      ),
    ));

    expect(find.text('ADD BOOKING'), findsOneWidget);
    expect(find.text('VENDOR'), findsOneWidget);
    expect(find.text('GENERATOR ASSIGNMENT'), findsOneWidget);
    expect(find.text('BOOKING DATES'), findsOneWidget);
  });
}
