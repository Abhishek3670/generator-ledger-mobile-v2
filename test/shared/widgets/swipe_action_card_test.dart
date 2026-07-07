import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ledger/shared/widgets/swipe_action_card.dart';

void main() {
  group('SwipeActionCard Widget Tests', () {
    testWidgets('renders child content successfully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCard(
              child: const Text('My Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('My Card Content'), findsOneWidget);
    });

    testWidgets('supports custom labels and icons', (WidgetTester tester) async {
      bool editTapped = false;
      bool cancelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCard(
              modifyLabel: 'Edit Booking',
              deleteLabel: 'Cancel Booking',
              modifyIcon: Icons.edit,
              deleteIcon: Icons.cancel,
              onModify: () => editTapped = true,
              onDelete: () => cancelTapped = true,
              child: const SizedBox(height: 50, child: Text('Booking Item')),
            ),
          ),
        ),
      );

      // Verify Slidable structure
      expect(find.byType(Slidable), findsOneWidget);
    });
  });
}
