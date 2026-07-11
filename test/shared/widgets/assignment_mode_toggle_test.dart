import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/assignment_mode_toggle.dart';

void main() {
  testWidgets('AssignmentModeToggle renders switch and triggers callback', (WidgetTester tester) async {
    String selectedMode = 'id';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return AssignmentModeToggle(
              currentMode: selectedMode,
              onModeChanged: (val) {
                setState(() {
                  selectedMode = val;
                });
              },
            );
          },
        ),
      ),
    ));

    expect(find.text('Assign by Generator ID'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    // Get the Switch widget
    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    // Tap on Switch to toggle to capacity mode
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(selectedMode, 'capacity');
    expect(find.text('Assign by Capacity'), findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    // Tap on Switch to toggle back to id mode
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(selectedMode, 'id');
    expect(find.text('Assign by Generator ID'), findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
  });
}
