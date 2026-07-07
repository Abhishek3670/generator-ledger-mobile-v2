import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/autocomplete_field.dart';

void main() {
  group('AutocompleteField Widget Tests', () {
    final testItems = ['Apple', 'Banana', 'Cherry', 'Date'];

    testWidgets('renders successfully with label and hint text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AutocompleteField<String>(
            items: testItems,
            displayStringForOption: (item) => item,
            searchFields: (item) => [item],
            onSelected: (_) {},
            hintText: 'Search fruit',
            labelText: 'FRUIT',
          ),
        ),
      ));

      expect(find.text('FRUIT'), findsOneWidget);
      expect(find.text('Search fruit'), findsOneWidget);
    });

    testWidgets('shows suggestions dropdown on focus and typing', (WidgetTester tester) async {
      String? selected;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AutocompleteField<String>(
            items: testItems,
            displayStringForOption: (item) => item,
            searchFields: (item) => [item],
            onSelected: (val) => selected = val,
            hintText: 'Search fruit',
            labelText: 'FRUIT',
          ),
        ),
      ));

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'a');
      await tester.pumpAndSettle();

      final bananaFinder = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('Banana'),
      );
      final appleFinder = find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('Apple'),
      );

      expect(bananaFinder, findsOneWidget);
      expect(appleFinder, findsOneWidget);

      await tester.tap(bananaFinder);
      await tester.pumpAndSettle();

      expect(selected, 'Banana');
    });

    testWidgets('shows No matches found when nothing fits query', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AutocompleteField<String>(
            items: testItems,
            displayStringForOption: (item) => item,
            searchFields: (item) => [item],
            onSelected: (_) {},
            hintText: 'Search fruit',
            labelText: 'FRUIT',
          ),
        ),
      ));

      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.enterText(textField, 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('No matches found'), findsOneWidget);
    });

    testWidgets('clears selection when clear button is tapped', (WidgetTester tester) async {
      String? selected = 'Banana';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AutocompleteField<String>(
            items: testItems,
            displayStringForOption: (item) => item,
            searchFields: (item) => [item],
            onSelected: (val) => selected = val,
            hintText: 'Search fruit',
            labelText: 'FRUIT',
            initialValue: 'Banana',
          ),
        ),
      ));

      expect(find.text('Banana'), findsOneWidget);

      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
