import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/app.dart';
import 'package:ledger/shared/widgets/side_navigation_drawer.dart';

void main() {
  testWidgets('renders the scaffold app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgerApp()));
    await tester.pumpAndSettle();

    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  testWidgets('app shell has centered Genset title and profile icon opens drawer', (tester) async {
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
  });
}
