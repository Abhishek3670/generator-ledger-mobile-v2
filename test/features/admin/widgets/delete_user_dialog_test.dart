import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/admin/widgets/delete_user_dialog.dart';

void main() {
  testWidgets('DeleteUserDialog renders successfully', (WidgetTester tester) async {
    final testUser = {
      'username': 'testuser',
      'role': 'operator',
      'status': 'ACTIVE',
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeleteUserDialog(
          user: testUser,
          onClose: () {},
          onDelete: () {},
        ),
      ),
    ));

    expect(find.text('DELETE USER'), findsOneWidget);
    expect(find.textContaining('testuser'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);
  });
}
