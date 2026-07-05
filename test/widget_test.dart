import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/app.dart';
import 'package:ledger/core/routing/app_router.dart';
import 'package:ledger/core/services/token_storage.dart';
import 'package:ledger/shared/widgets/side_navigation_drawer.dart';

void main() {
  setUp(() {
    AppRouter.tokenStorage = TokenStorage(backend: _FakeTokenStorageBackend());
  });

  testWidgets('unauthenticated launch renders login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(SideNavigationDrawer), findsNothing);
  });

  testWidgets(
    'authenticated app shell has centered Genset title and profile icon opens drawer',
    (tester) async {
      await AppRouter.tokenStorage.saveToken('jwt-token');

      await tester.pumpWidget(const ProviderScope(child: LedgerApp()));
      await tester.pumpAndSettle();

      expect(find.text('Genset'), findsOneWidget);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);

      final appBarProfileIcon = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(CircleAvatar),
      );
      expect(appBarProfileIcon, findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Tap profile avatar to open drawer
      await tester.tap(appBarProfileIcon);
      await tester.pumpAndSettle();
      expect(find.byType(SideNavigationDrawer), findsOneWidget);
    },
  );
}

class _FakeTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}
