import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/confirmation_dialog.dart';
import 'package:ledger/shared/widgets/destructive_confirmation_dialog.dart';

void main() {
  group('ConfirmationDialog Tests', () {
    testWidgets('renders ConfirmationDialog successfully with correct texts', (
      tester,
    ) async {
      bool confirmCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'TEST CONFIRMATION',
              message: 'This is a test confirmation message.',
              confirmText: 'YES',
              cancelText: 'NO',
              onConfirm: () => confirmCalled = true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('TEST CONFIRMATION'), findsOneWidget);
      expect(find.text('This is a test confirmation message.'), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);

      await tester.tap(find.text('YES'));
      await tester.pump();
      expect(confirmCalled, isTrue);

      await tester.tap(find.text('NO'));
      await tester.pump();
      expect(cancelCalled, isTrue);
    });
  });

  group('DestructiveConfirmationDialog Tests', () {
    testWidgets(
      'confirm button is disabled until correct word is typed, and confirm works',
      (tester) async {
        bool confirmCalled = false;
        bool cancelCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DestructiveConfirmationDialog(
                title: 'DELETE ITEM',
                message: 'This action is dangerous.',
                onConfirm: () => confirmCalled = true,
                onCancel: () => cancelCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('DELETE ITEM'), findsOneWidget);
        expect(find.text('This action is dangerous.'), findsOneWidget);

        // Confirm button should be disabled initially
        final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'DELETE');
        expect(confirmButtonFinder, findsOneWidget);
        
        ElevatedButton button = tester.widget<ElevatedButton>(confirmButtonFinder);
        expect(button.enabled, isFalse);

        // Type incorrect text
        await tester.enterText(find.byType(TextField), 'WRONG');
        await tester.pump();
        button = tester.widget<ElevatedButton>(confirmButtonFinder);
        expect(button.enabled, isFalse);

        // Type correct text
        await tester.enterText(find.byType(TextField), 'DELETE');
        await tester.pump();
        button = tester.widget<ElevatedButton>(confirmButtonFinder);
        expect(button.enabled, isTrue);

        // Tap confirm
        await tester.tap(confirmButtonFinder);
        await tester.pump();
        expect(confirmCalled, isTrue);

        // Tap cancel
        await tester.tap(find.text('CANCEL'));
        await tester.pump();
        expect(cancelCalled, isTrue);
      },
    );
  });
}
