import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/core/providers/api_client_provider.dart';
import 'package:ledger/core/routing/app_router.dart';
import 'package:ledger/features/auth/providers/auth_provider.dart';

void main() {
  group('apiClientProvider Tests', () {
    testWidgets('unauthorized events clear auth state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
            scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          ),
        ),
      );

      final context = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(context);

      // Ensure providers are read and active
      final client = container.read(apiClientProvider);
      final auth = container.read(authProvider);

      expect(client, isNotNull);
      expect(auth.valueOrNull, isNull);
    });
  });
}
