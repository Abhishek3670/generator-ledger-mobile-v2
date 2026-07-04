import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/capacity_chip_selector.dart';

void main() {
  testWidgets('CapacityChipSelector renders single select chips successfully', (WidgetTester tester) async {
    String selected = '50';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CapacityChipSelector(
          capacities: const ['25', '50', '100'],
          selectedCapacity: selected,
          onCapacitySelected: (val) {
            selected = val;
          },
        ),
      ),
    ));

    expect(find.text('25'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);

    // Tap on '100'
    await tester.tap(find.text('100'));
    await tester.pump();
    expect(selected, '100');
  });

  testWidgets('CapacityChipSelector renders multi select chips successfully', (WidgetTester tester) async {
    List<String> selected = ['30'];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return CapacityChipSelector(
              capacities: const ['20', '30', '50'],
              selectedCapacities: selected,
              isMultiSelect: true,
              onCapacitiesChanged: (val) {
                setState(() {
                  selected = val;
                });
              },
            );
          },
        ),
      ),
    ));

    expect(find.text('20 kVA'), findsOneWidget);
    expect(find.text('30 kVA'), findsOneWidget);
    expect(find.text('50 kVA'), findsOneWidget);

    // Tap on '50 kVA' to select it
    await tester.tap(find.text('50 kVA'));
    await tester.pump();
    expect(selected, containsAll(['30', '50']));

    // Tap on '30 kVA' to deselect it
    await tester.tap(find.text('30 kVA'));
    await tester.pump();
    expect(selected, contains('50'));
    expect(selected, isNot(contains('30')));
  });
}
