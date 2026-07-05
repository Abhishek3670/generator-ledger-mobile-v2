import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/generators/widgets/generator_card.dart';
import 'package:ledger/shared/models/generator.dart';

void main() {
  testWidgets('GeneratorCard renders details correctly', (WidgetTester tester) async {
    const generator = Generator(
      id: 'GEN-001',
      capacity: '100 kVA',
      type: '6R',
      status: 'active',
      category: 'permanent',
      assignedVendor: 'Test Vendor Name',
    );

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GeneratorCard(generator: generator),
      ),
    ));

    expect(find.text('GEN-001'), findsOneWidget);
    expect(find.text('Cap: 100 kVA | Type: 6R'), findsOneWidget);
    expect(find.text('ASSIGNED TO: '), findsOneWidget);
    expect(find.text('Test Vendor Name'), findsOneWidget);
  });

  testWidgets('GeneratorCard handles long text and does not crash', (WidgetTester tester) async {
    const longGenerator = Generator(
      id: 'GEN-VERY-LONG-GENERATOR-ID-THAT-COULD-OVERFLOW-THE-CONTAINER-WIDTH',
      capacity: 'Very Long Capacity That Spans Multiple Characters and Words',
      type: 'Very Long Type Engine Model and Manufacturer Specific Details',
      status: 'active',
      category: 'permanent',
      assignedVendor: 'Very Long Vendor Name Assigned to This Specific Generator Unit to Prevent Overflows',
    );

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: GeneratorCard(generator: longGenerator),
      ),
    ));

    expect(find.text(longGenerator.id), findsOneWidget);
    expect(find.text('Cap: ${longGenerator.capacity} | Type: ${longGenerator.type}'), findsOneWidget);
    expect(find.text(longGenerator.assignedVendor!), findsOneWidget);
  });
}
