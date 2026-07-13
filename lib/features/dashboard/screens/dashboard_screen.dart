import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/connectivity_service.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/generator_provider.dart';
import '../../../core/providers/vendor_provider.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../widgets/calendar_view.dart';
import '../widgets/daily_bookings_list.dart';
import '../widgets/stats_grid.dart';

/// The main dashboard landing screen after sign-in.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final allVendorBookingsState = ref.watch(allVendorBookingsProvider);
    final generatorState = ref.watch(generatorProvider);
    final vendorState = ref.watch(vendorProvider);
    final connectivity = ref.watch(connectivityProvider);
    
    final summary = ref.watch(dashboardSummaryProvider);
    final allBookingsMap = allVendorBookingsState.valueOrNull ?? {};
    final bookings = allBookingsMap.values.expand((list) => list).toList();

    if (bookingState.isLoading || allVendorBookingsState.isLoading || generatorState.isLoading || vendorState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: SkeletonCard(height: 90, borderRadius: 12)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonCard(height: 90, borderRadius: 12)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonCard(height: 90, borderRadius: 12)),
                  ],
                ),
                SizedBox(height: 24),
                SkeletonCard(height: 160, borderRadius: 16),
                SizedBox(height: 24),
                SkeletonText(height: 20, width: 150),
                SizedBox(height: 12),
                SkeletonCard(height: 80, borderRadius: 12),
                SizedBox(height: 12),
                SkeletonCard(height: 80, borderRadius: 12),
              ],
            ),
          ),
        ),
      );
    }

    if (bookingState.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorScreen(
          message: 'Error loading bookings: ${bookingState.error}',
          onRetry: () => ref.read(bookingProvider.notifier).loadBookings(),
        ),
      );
    }
    if (allVendorBookingsState.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorScreen(
          message: 'Error loading vendor bookings: ${allVendorBookingsState.error}',
          onRetry: () => ref.read(allVendorBookingsProvider.notifier).loadBookings(),
        ),
      );
    }
    if (generatorState.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorScreen(
          message: 'Error loading generators: ${generatorState.error}',
          onRetry: () => ref.read(generatorProvider.notifier).loadGenerators(),
        ),
      );
    }
    if (vendorState.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorScreen(
          message: 'Error loading vendors: ${vendorState.error}',
          onRetry: () => ref.read(vendorProvider.notifier).loadVendors(),
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(bookingProvider.notifier).loadBookings(),
              ref.read(allVendorBookingsProvider.notifier).loadBookings(),
              ref.read(generatorProvider.notifier).loadGenerators(),
              ref.read(vendorProvider.notifier).loadVendors(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.mobileGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (connectivity.value == ConnectivityResult.none) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, color: AppColors.warningText, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Offline Mode - Viewing Cached Data',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warningText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // 1. Stats summary grid
                StatsGrid(
                  totalBookings: summary.totalBookings,
                  totalGensets: summary.totalGenerators,
                  totalVendors: summary.totalVendors,
                  generatorsByCategory: summary.generatorsByCategory,
                  vendorsByCategory: summary.vendorsByCategory,
                ),
                const SizedBox(height: 20),

                // 2. Calendar Month View
                CalendarView(
                  selectedDay: _selectedDay,
                  focusedDay: _focusedDay,
                  bookings: bookings.where((b) => b.status.toLowerCase() == 'confirmed').toList(),
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
                  bookings: bookings,
                  onViewAllPressed: () {
                    context.go('/bookings');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
