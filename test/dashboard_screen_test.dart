import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/features/dashboard/screens/dashboard_screen.dart';
import 'package:ledger/features/dashboard/widgets/stats_grid.dart';
import 'package:ledger/features/dashboard/widgets/calendar_view.dart';
import 'package:ledger/features/dashboard/widgets/daily_bookings_list.dart';

void main() {
  testWidgets('DashboardScreen renders successfully with all sub-widgets', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DashboardScreen(),
    ));

    // Verify Dashboard Scaffold components
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);

    // Verify StatsGrid exists
    expect(find.byType(StatsGrid), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);

    // Verify CalendarView exists
    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.text('CALENDAR'), findsOneWidget);
    expect(find.text('Vendor Bookings'), findsOneWidget);

    // Verify DailyBookingsList exists
    expect(find.byType(DailyBookingsList), findsOneWidget);
    expect(find.text('BOOKINGS'), findsAtLeastNWidgets(1));
    expect(find.text('Daily Schedule'), findsOneWidget);
    expect(find.text('VIEW ALL BOOKINGS'), findsOneWidget);
  });
}
