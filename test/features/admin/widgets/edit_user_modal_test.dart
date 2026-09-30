import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/admin/modals/edit_user_modal.dart';

void main() {
  testWidgets('EditUserModal renders successfully', (WidgetTester tester) async {
    final testUser = {
      'username': 'testuser',
      'role': 'operator',
      'status': 'ACTIVE',
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditUserModal(
          user: testUser,
          onClose: () {},
          onSave: (_) {},
        ),
      ),
    ));

    expect(find.text('Edit User'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('ROLE'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
  });
}
