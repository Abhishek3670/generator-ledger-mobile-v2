import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/generators/modals/edit_generator_modal.dart';
import 'package:ledger/shared/models/generator.dart';

void main() {
  testWidgets('EditGeneratorModal renders successfully', (WidgetTester tester) async {
    const testGen = Generator(
      id: 'GEN-TEST',
      capacity: '100 kVA',
      type: 'Silent',
      status: 'active',
      category: 'retailer',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditGeneratorModal(
          generator: testGen,
          onClose: () {},
          onSave: (_) {},
        ),
      ),
    ));

    expect(find.text('EDIT GENERATOR'), findsOneWidget);
    expect(find.text('GENERATOR ID'), findsOneWidget);
    expect(find.text('CAPACITY (kVA)'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
  });
}
