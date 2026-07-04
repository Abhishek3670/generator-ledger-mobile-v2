import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/features/dashboard/screens/dashboard_screen.dart';
import 'package:ledger/features/dashboard/widgets/stats_grid.dart';
import 'package:ledger/features/dashboard/widgets/calendar_view.dart';
import 'package:ledger/features/dashboard/widgets/daily_bookings_list.dart';

void main() {
  testWidgets('DashboardScreen renders successfully with all sub-widgets', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: DashboardScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Dashboard Scaffold components
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Verify StatsGrid exists
    expect(find.byType(StatsGrid), findsOneWidget);
    expect(find.text('8 confirmed'), findsOneWidget);
    expect(find.text('4 active'), findsOneWidget);
    expect(find.text('9 partners'), findsOneWidget);

    // Verify CalendarView exists
    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.text('CALENDAR'), findsOneWidget);
    expect(find.text('Vendor Bookings'), findsOneWidget);

    // Verify DailyBookingsList exists
    expect(find.byType(DailyBookingsList), findsOneWidget);
    expect(find.textContaining('Bookings:'), findsOneWidget);
    expect(find.textContaining('VIEW ALL'), findsOneWidget);
  });
}
