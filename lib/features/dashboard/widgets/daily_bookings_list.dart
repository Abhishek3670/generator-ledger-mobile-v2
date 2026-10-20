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
      final dayOnly = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      final start = DateTime(b.startDate.year, b.startDate.month, b.startDate.day);
      final end = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
      return !dayOnly.isBefore(start) && !dayOnly.isAfter(end);
    }).toList();

    final vendorGroups = <String, List<Booking>>{};
    for (final booking in dailyBookings) {
      final vendorKey = booking.vendorName.isNotEmpty
          ? booking.vendorName
          : (booking.vendorId.isNotEmpty ? booking.vendorId : 'Unknown Vendor');
      vendorGroups.putIfAbsent(vendorKey, () => []).add(booking);
    }
    final vendorEntries = vendorGroups.entries.toList();

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
              Expanded(
                child: Text(
                  'Bookings: $formattedDate',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
              itemCount: vendorEntries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = vendorEntries[index];
                final vendorName = entry.key;
                final vendorBookings = entry.value;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.functionalRadius - 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vendor Header Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            border: const Border(
                              bottom: BorderSide(color: AppColors.border, width: 1),
                            ),
                          ),
                          child: Text(
                            vendorName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Bookings under this vendor
                        ...List.generate(vendorBookings.length, (bookingIndex) {
                          final booking = vendorBookings[bookingIndex];
                          final isLast = bookingIndex == vendorBookings.length - 1;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CompactBookingRow(
                                booking: booking,
                                showVendor: false,
                                isCard: false,
                                onTap: () {
                                  // Navigate to booking details (omitted for now)
                                },
                              ),
                              if (!isLast)
                                const Divider(
                                  color: AppColors.border,
                                  height: 1,
                                  thickness: 1,
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
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
