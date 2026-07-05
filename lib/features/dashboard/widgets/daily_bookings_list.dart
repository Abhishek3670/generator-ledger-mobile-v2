import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import 'compact_booking_row.dart';
/// List displaying bookings for the selected date inside a single compact bordered container.
class DailyBookingsList extends StatelessWidget {
  /// The currently selected day.
  final DateTime selectedDay;

  /// The list of bookings.
  final List<Booking> bookings;

  /// Callback triggered when the "View All Bookings" button is pressed.
  final VoidCallback onViewAllPressed;

  /// Creates a [DailyBookingsList].
  const DailyBookingsList({
    super.key,
    required this.selectedDay,
    required this.bookings,
    required this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dailyBookings = bookings.where((b) {
      return b.date.year == selectedDay.year &&
          b.date.month == selectedDay.month &&
          b.date.day == selectedDay.day;
    }).toList();

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: AppColors.shadowSoft,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header inside container
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bookings: $formattedDate',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${dailyBookings.length} Total',
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          if (dailyBookings.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Center(
                child: Text(
                  'No bookings scheduled for this date.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dailyBookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final booking = dailyBookings[index];
                return CompactBookingRow(
                  booking: booking,
                  onTap: () {
                    // Navigate to booking details (omitted for now)
                  },
                );
              },
            ),

          const SizedBox(height: 16),

          // View All Button
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onViewAllPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                'View All ${dailyBookings.length} Bookings'.toUpperCase(),
                style: AppTypography.labelCaps.copyWith(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
