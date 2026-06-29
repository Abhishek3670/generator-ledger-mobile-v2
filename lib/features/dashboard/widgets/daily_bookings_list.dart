import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../shared/widgets/directory_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// List displaying mock bookings for the selected date.
class DailyBookingsList extends StatelessWidget {
  /// The currently selected day.
  final DateTime selectedDay;

  /// The list of mock bookings.
  final List<MockBooking> bookings;

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

    final formattedDate = DateFormat('MMMM d, yyyy').format(selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOOKINGS',
                  style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Daily Schedule',
                  style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (dailyBookings.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = dailyBookings[index];
              final statusType = _getStatusBadgeType(booking.status);

              return DirectoryCard(
                headerTitle: booking.vendorName,
                headerAction: StatusBadge(
                  label: booking.status.toUpperCase(),
                  type: statusType,
                ),
                hasDarkHeader: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKeyValuePair('Booking ID', booking.id),
                          const SizedBox(height: 4),
                          _buildKeyValuePair('Genset ID', booking.generatorId),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 20),

        // View All Button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onViewAllPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'VIEW ALL BOOKINGS',
              style: AppTypography.labelCaps.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyValuePair(String key, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$key:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  StatusBadgeType _getStatusBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusBadgeType.confirmed;
      case 'pending':
        return StatusBadgeType.pending;
      case 'cancelled':
      default:
        return StatusBadgeType.cancelled;
    }
  }
}
