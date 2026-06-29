import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders brand, inputs, and button successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    // Verify Brand Header
    expect(find.text('GENSET'), findsOneWidget);

    // Verify Form Header
    expect(find.text('ACCESS'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Use your username and password to continue.'), findsOneWidget);

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
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    // Tap without inputting username/password
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Verify it doesn't navigate / crash (validation fails quietly and doesn't crash)
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('LoginScreen inputs text successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    // Enter username
    await tester.enterText(find.byKey(const Key('input_username')), 'admin');
    await tester.enterText(find.byKey(const Key('input_password')), 'secret123');
    await tester.pump();

    expect(find.text('admin'), findsOneWidget);
    // password text is obscured, so we verify that the value is correctly passed to the controller
    final passwordField = tester.widget<TextFormField>(find.byKey(const Key('input_password')));
    expect(passwordField.controller?.text, 'secret123');
  });
}
