import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/admin/screens/user_management_screen.dart';
import 'package:ledger/features/admin/modals/add_user_modal.dart';

void main() {
  testWidgets('UserManagementScreen renders users list and permission matrix', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: UserManagementScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('User Management'), findsOneWidget);

    // Verify presence of default mock users from userProvider
    expect(find.text('manohar'), findsNWidgets(2));
    expect(find.text('abhishek'), findsOneWidget);

    // Verify access control header & permission matrix table
    expect(find.text('ACCESS CONTROL'), findsOneWidget);
    expect(find.text('Permission Matrix'), findsOneWidget);

    // Verify table capability rows exist
    expect(find.text('Settings & User Admin'), findsOneWidget);
    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Vendor Management'), findsOneWidget);

    // Verify FloatingActionButton (FAB) is present
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Verify clicking FAB opens the AddUserModal
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddUserModal), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
  });
}
