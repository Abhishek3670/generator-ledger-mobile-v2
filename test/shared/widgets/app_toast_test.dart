import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/app_toast.dart';

void main() {
  group('AppToast Widget Tests', () {
    testWidgets('AppToast renders successfully and shows correct content for each variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'Success Notification',
                        type: ToastType.success,
                      );
                    },
                    child: const Text('Show Success'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'Warning Notification',
                        type: ToastType.warning,
                      );
                    },
                    child: const Text('Show Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'Error Notification',
                        type: ToastType.error,
                      );
                    },
                    child: const Text('Show Error'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 1. Verify Success Toast
      await tester.tap(find.text('Show Success'));
      await tester.pump();
      expect(find.text('Success Notification'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      // 2. Verify Warning Toast (replaces previous one)
      await tester.tap(find.text('Show Warning'));
      await tester.pump();
      expect(find.text('Success Notification'), findsNothing);
      expect(find.text('Warning Notification'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // 3. Verify Error Toast
      await tester.tap(find.text('Show Error'));
      await tester.pump();
      expect(find.text('Warning Notification'), findsNothing);
      expect(find.text('Error Notification'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // 4. Wait for auto-dismiss
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Error Notification'), findsNothing);
    });
  });
}
