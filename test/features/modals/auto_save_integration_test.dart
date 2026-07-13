import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledger/features/vendors/modals/add_vendor_modal.dart';
import 'package:ledger/core/services/draft_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auto-Save Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('AddVendorModal auto-saves and resumes correctly', (WidgetTester tester) async {
      final draftService = DraftService();

      // Render AddVendorModal
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddVendorModal(
                key: const ValueKey('first_render'),
                onClose: () {},
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter name
      final nameFinder = find.widgetWithText(TextFormField, 'Enter Vendor Name');
      expect(nameFinder, findsOneWidget);
      await tester.enterText(nameFinder, 'Test Auto Save Vendor');

      // Wait 2.5 seconds to trigger auto-save timer
      await tester.pump(const Duration(milliseconds: 2500));

      // Verify that draft was saved
      final draft = await draftService.loadDraft('add_vendor');
      expect(draft, isNotNull);
      expect(draft!['name'], 'Test Auto Save Vendor');

      // Re-render the modal with a different key to force initState
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddVendorModal(
                key: const ValueKey('second_render'),
                onClose: () {},
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );

      // Wait for post-frame callback, future execution, and dialog rendering
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify "Resume Draft?" dialog appears
      expect(find.text('Resume Draft?'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      // Verify values were restored
      expect(find.text('Test Auto Save Vendor'), findsOneWidget);
    });

    testWidgets('AddVendorModal discards draft correctly', (WidgetTester tester) async {
      final draftService = DraftService();
      await draftService.saveDraft('add_vendor', {'name': 'Discard Me'});

      // Render AddVendorModal
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddVendorModal(
                onClose: () {},
                onSave: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify Dialog appears
      expect(find.text('Resume Draft?'), findsOneWidget);

      // Tap Discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Verify input field does not contain the draft name
      expect(find.text('Discard Me'), findsNothing);

      // Verify draft in storage is cleared
      expect(await draftService.loadDraft('add_vendor'), isNull);
    });
  });
}
