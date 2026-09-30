import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ledger/data/models/login_response.dart';
import 'package:ledger/data/repositories/auth_repository.dart';
import 'package:ledger/features/auth/providers/auth_provider.dart';
import 'package:ledger/features/auth/screens/login_screen.dart';
import 'package:ledger/shared/models/user.dart';

void main() {
  testWidgets('LoginScreen renders brand, inputs, and button successfully', (
    tester,
  ) async {
    await tester.pumpWidget(_loginScreenApp());

    // Verify Brand Header
    expect(find.text('GENSET'), findsOneWidget);

    // Verify Form Header
    expect(find.text('ACCESS'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.text('Use your username and password to continue.'),
      findsOneWidget,
    );

    // Verify Fields & Labels
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);

    // Verify Username input field key
    expect(find.byKey(const Key('input_username')), findsOneWidget);
    expect(find.byKey(const Key('input_password')), findsOneWidget);

    // Verify Button
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('LoginScreen Sign In button triggers validation', (tester) async {
    await tester.pumpWidget(_loginScreenApp());

    // Tap without inputting username/password
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Verify it doesn't navigate / crash (validation fails quietly and doesn't crash)
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LoginScreen inputs text successfully', (tester) async {
    await tester.pumpWidget(_loginScreenApp());

    // Enter username
    await tester.enterText(find.byKey(const Key('input_username')), 'admin');
    await tester.enterText(
      find.byKey(const Key('input_password')),
      'secret123',
    );
    await tester.pump();

    expect(find.text('admin'), findsOneWidget);
    // password text is obscured, so we verify that the value is correctly passed to the controller
    final passwordField = tester.widget<TextFormField>(
      find.byKey(const Key('input_password')),
    );
    expect(passwordField.controller?.text, 'secret123');
  });

  testWidgets(
    'LoginScreen shows loading and navigates after successful login',
    (tester) async {
      final repository = _FakeAuthRepository();
      await tester.pumpWidget(_loginScreenApp(repository: repository));

      await tester.enterText(find.byKey(const Key('input_username')), 'owner');
      await tester.enterText(
        find.byKey(const Key('input_password')),
        'Qwerty@345',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.completeLogin();
      await tester.pumpAndSettle();

      expect(repository.username, 'owner');
      expect(repository.password, 'Qwerty@345');
      expect(find.text('Dashboard'), findsOneWidget);
    },
  );

  testWidgets('LoginScreen shows an error when login fails', (tester) async {
    final repository = _FakeAuthRepository(
      error: Exception('Invalid credentials'),
    );
    await tester.pumpWidget(_loginScreenApp(repository: repository));

    await tester.enterText(find.byKey(const Key('input_username')), 'owner');
    await tester.enterText(
      find.byKey(const Key('input_password')),
      'bad-password',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

Widget _loginScreenApp({_FakeAuthRepository? repository}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error});

  final Object? error;
  final _loginCompleter = Completer<LoginResponse>();
  String? username;
  String? password;

  void completeLogin() {
    _loginCompleter.complete(
      LoginResponse(
        token: 'jwt-token',
        user: User(
          username: username ?? 'owner',
          role: 'admin',
          status: 'ACTIVE',
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Future<LoginResponse> login(String username, String password) {
    this.username = username;
    this.password = password;
    if (error != null) {
      return Future<LoginResponse>.error(error!);
    }
    return _loginCompleter.future;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<bool> verifyToken() async => false;
}
