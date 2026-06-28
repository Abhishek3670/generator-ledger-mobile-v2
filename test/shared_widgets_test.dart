import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/shared/widgets/admin_bottom_nav_bar.dart';
import 'package:ledger/shared/widgets/app_bottom_nav_bar.dart';
import 'package:ledger/shared/widgets/backdrop_blur_overlay.dart';
import 'package:ledger/shared/widgets/dark_header_card.dart';
import 'package:ledger/shared/widgets/directory_card.dart';
import 'package:ledger/shared/widgets/expandable_fab_menu.dart';
import 'package:ledger/shared/widgets/floating_search_fab.dart';
import 'package:ledger/shared/widgets/modal_scaffold.dart';
import 'package:ledger/shared/widgets/section_header.dart';
import 'package:ledger/shared/widgets/side_navigation_drawer.dart';
import 'package:ledger/shared/widgets/status_badge.dart';
import 'package:ledger/shared/widgets/swipe_action_card.dart';

void main() {
  testWidgets('AppBottomNavBar renders successfully', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    ));
    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  testWidgets('AdminBottomNavBar renders successfully', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: AdminBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    ));
    expect(find.byType(AdminBottomNavBar), findsOneWidget);
    expect(find.text('HEALTH'), findsOneWidget);
  });

  testWidgets('BackdropBlurOverlay renders successfully when visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            BackdropBlurOverlay(isVisible: true),
          ],
        ),
      ),
    ));
    expect(find.byType(BackdropBlurOverlay), findsOneWidget);
  });

  testWidgets('FloatingSearchFAB renders successfully', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FloatingSearchFAB(
          searchHint: 'Search test',
          fabIcon: Icons.add,
          onFABPressed: () {},
        ),
      ),
    ));
    expect(find.byType(FloatingSearchFAB), findsOneWidget);
    expect(find.text('Search test'), findsOneWidget);
  });

  testWidgets('ExpandableFABMenu renders successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        floatingActionButton: ExpandableFABMenu(
          items: [
            ExpandableFABItem(icon: Icons.add, label: 'Add Item', onPressed: _dummy),
          ],
        ),
      ),
    ));
    expect(find.byType(ExpandableFABMenu), findsOneWidget);
  });

  testWidgets('StatusBadge renders successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatusBadge(
          label: 'CONFIRMED',
          type: StatusBadgeType.confirmed,
        ),
      ),
    ));
    expect(find.byType(StatusBadge), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);
  });

  testWidgets('DirectoryCard renders successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DirectoryCard(
          headerTitle: 'Card Title',
          child: Text('Card Content'),
        ),
      ),
    ));
    expect(find.byType(DirectoryCard), findsOneWidget);
    expect(find.text('Card Title'), findsOneWidget);
    expect(find.text('Card Content'), findsOneWidget);
  });

  testWidgets('DarkHeaderCard renders successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DarkHeaderCard(
          title: 'Dark Title',
          child: Text('Content'),
        ),
      ),
    ));
    expect(find.byType(DarkHeaderCard), findsOneWidget);
    expect(find.text('Dark Title'), findsOneWidget);
  });

  testWidgets('SectionHeader renders successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SectionHeader(
          category: 'Category',
          title: 'Section Title',
          description: 'Section Description',
        ),
      ),
    ));
    expect(find.byType(SectionHeader), findsOneWidget);
    expect(find.text('CATEGORY'), findsOneWidget);
    expect(find.text('Section Title'), findsOneWidget);
    expect(find.text('Section Description'), findsOneWidget);
  });

  testWidgets('ModalScaffold renders successfully', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ModalScaffold(
          title: 'Modal Title',
          body: const Text('Modal Body'),
          onClose: () {},
        ),
      ),
    ));
    expect(find.byType(ModalScaffold), findsOneWidget);
    expect(find.text('Modal Title'), findsOneWidget);
    expect(find.text('Modal Body'), findsOneWidget);
  });

  testWidgets('SwipeActionCard renders successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SwipeActionCard(
          child: Text('Swipe Content'),
        ),
      ),
    ));
    expect(find.byType(SwipeActionCard), findsOneWidget);
    expect(find.text('Swipe Content'), findsOneWidget);
  });

  testWidgets('SideNavigationDrawer renders successfully', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        drawer: SideNavigationDrawer(
          currentRoute: '/dashboard',
          onNavigate: (_) {},
          userName: 'Abhishek',
          userRole: 'Fleet Manager',
        ),
      ),
    ));
    scaffoldKey.currentState?.openDrawer();
    await tester.pump();
    expect(find.byType(SideNavigationDrawer), findsOneWidget);
    expect(find.text('Abhishek'), findsOneWidget);
    expect(find.text('Fleet Manager'), findsOneWidget);
  });
}

void _dummy() {}
