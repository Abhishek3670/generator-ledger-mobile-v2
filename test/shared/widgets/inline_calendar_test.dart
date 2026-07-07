import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/inline_calendar.dart';

void main() {
  testWidgets('InlineCalendar renders successfully with weekday headers and days grid', (WidgetTester tester) async {
    DateTime? start = DateTime.utc(2026, 7, 4);
    DateTime? end = DateTime.utc(2026, 7, 8);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InlineCalendar(
          startDate: start,
          endDate: end,
          onRangeSelected: (s, e) {
            start = s;
            end = e;
          },
        ),
      ),
    ));

    // Verify header showing month and year (should contain "July 2026")
    expect(find.textContaining('July 2026'), findsOneWidget);

    // Verify weekday headers (S M T W T F S)
    expect(find.text('S'), findsNWidgets(2)); // Sunday, Saturday (and headers contain 'S' twice)
    expect(find.text('M'), findsOneWidget);
    expect(find.text('T'), findsNWidgets(2)); // Tuesday, Thursday
    expect(find.text('W'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);

    // Verify presence of day numbers (e.g. 4 and 8)
    expect(find.text('4'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('InlineCalendar supports multi-selection mode and notifies listeners when days are tapped', (WidgetTester tester) async {
    List<DateTime> selectedDates = [];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return InlineCalendar(
              startDate: DateTime.utc(2026, 7, 1),
              selectionMode: CalendarSelectionMode.multi,
              selectedDates: selectedDates,
              onDatesChanged: (dates) {
                setState(() {
                  selectedDates = dates;
                });
              },
            );
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap on July 8 (or whatever day number is visible and active)
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    // Verify July 8 is selected
    expect(selectedDates.length, 1);
    expect(selectedDates.first.day, 8);

    // Tap July 8 again to deselect
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    // Verify list is empty
    expect(selectedDates.isEmpty, true);
  });
}
