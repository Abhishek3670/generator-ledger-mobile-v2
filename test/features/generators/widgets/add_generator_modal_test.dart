import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/generators/widgets/add_generator_modal.dart';

void main() {
  testWidgets('AddGeneratorModal renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddGeneratorModal(
          onClose: () {},
          onSave: (_) {},
        ),
      ),
    ));

    expect(find.text('ADD GENERATOR'), findsOneWidget);
    expect(find.text('GENERATOR ID'), findsOneWidget);
    expect(find.text('CAPACITY (kVA)'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
  });
}
