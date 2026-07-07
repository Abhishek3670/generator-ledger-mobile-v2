import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/generators/modals/add_generator_modal.dart';

void main() {
  testWidgets('AddGeneratorModal renders successfully and keeps category dropdown enabled by default', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AddGeneratorModal(
            onClose: () {},
            onSave: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('ADD GENERATOR'), findsOneWidget);
    expect(find.text('GENERATOR ID'), findsOneWidget);
    expect(find.text('CAPACITY (kVA)'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);

    final dropdown = tester.firstWidget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(dropdown.onChanged, isNotNull);
  });

  testWidgets('AddGeneratorModal renders successfully and disables category dropdown when initialCategory is provided', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AddGeneratorModal(
            initialCategory: 'retailer',
            onClose: () {},
            onSave: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('ADD GENERATOR'), findsOneWidget);
    expect(find.text('GENERATOR ID'), findsOneWidget);

    final dropdown = tester.firstWidget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(dropdown.onChanged, isNull);
  });
}
