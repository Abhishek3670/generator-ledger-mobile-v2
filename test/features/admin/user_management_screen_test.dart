import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/user_provider.dart';
import 'package:ledger/data/mock/mock_users.dart';
import 'package:ledger/data/repositories/user_repository.dart';
import 'package:ledger/shared/models/user.dart';
import 'package:ledger/shared/models/permission.dart';
import 'package:ledger/features/admin/screens/user_management_screen.dart';
import 'package:ledger/features/admin/modals/add_user_modal.dart';

void main() {
  testWidgets('UserManagementScreen renders users list and permission matrix', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(_FakeUserRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: UserManagementScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('CREATE USER'), findsNothing);

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

class _FakeUserRepository extends UserRepository {
  @override
  Future<List<User>> getUsers() async {
    return List.of(mockUsers);
  }

  @override
  Future<List<Permission>> getPermissions() async {
    return [
      const Permission(
        capability: 'settings_user_admin',
        label: 'Settings & User Admin',
        description: 'Manage users and settings',
        admin: true,
        operator: false,
      ),
      const Permission(
        capability: 'monitor',
        label: 'Monitor',
        description: 'View health metrics',
        admin: true,
        operator: true,
      ),
      const Permission(
        capability: 'vendor_management',
        label: 'Vendor Management',
        description: 'Manage vendors',
        admin: true,
        operator: true,
      ),
    ];
  }

  @override
  Future<User> createUser(User user) async {
    return user;
  }
}

