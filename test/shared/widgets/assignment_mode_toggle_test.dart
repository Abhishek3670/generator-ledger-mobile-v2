import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/assignment_mode_toggle.dart';

void main() {
  testWidgets('AssignmentModeToggle renders both buttons and triggers callback', (WidgetTester tester) async {
    String selectedMode = 'id';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AssignmentModeToggle(
          currentMode: selectedMode,
          onModeChanged: (val) {
            selectedMode = val;
          },
        ),
      ),
    ));

    expect(find.text('Assign by Generator ID'), findsOneWidget);
    expect(find.text('Assign by Capacity (Auto-assign)'), findsOneWidget);

    // Tap on capacity option
    await tester.tap(find.text('Assign by Capacity (Auto-assign)'));
    await tester.pump();
    expect(selectedMode, 'capacity');

    // Tap back to id option
    await tester.tap(find.text('Assign by Generator ID'));
    await tester.pump();
    expect(selectedMode, 'id');
  });
}
