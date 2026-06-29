import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';
import '../widgets/calendar_view.dart';
import '../widgets/daily_bookings_list.dart';
import '../widgets/stats_grid.dart';

/// The main dashboard landing screen after sign-in.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Standard mock summary counts matching HTML design spec values
    const totalBookings = 128;
    const totalGensets = 33;
    const totalVendors = 50;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'DASHBOARD',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: SideNavigationDrawer(
        currentRoute: '/dashboard',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: 'Abhishek Sharma',
        userRole: 'Fleet Manager',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.mobileGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stats summary grid
              const StatsGrid(
                totalBookings: totalBookings,
                totalGensets: totalGensets,
                totalVendors: totalVendors,
              ),
              const SizedBox(height: 20),

              // 2. Calendar Month View
              CalendarView(
                selectedDay: _selectedDay,
                focusedDay: _focusedDay,
                bookings: mockBookings,
                onDaySelected: (selectedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = selectedDay;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 3. Daily Bookings schedule list
              DailyBookingsList(
                selectedDay: _selectedDay,
                bookings: mockBookings,
                onViewAllPressed: () {
                  context.go('/bookings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
