import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../data/mock/mock_vendors.dart';
import '../../../shared/widgets/dark_header_card.dart';
import 'booking_list_item.dart';

/// Group card displaying a list of bookings for a single vendor inside a dark header card.
class VendorBookingGroup extends StatelessWidget {
  /// The vendor information for this group.
  final MockVendor vendor;

  /// The list of bookings associated with this vendor.
  /// The list of bookings associated with this vendor.
  final List<Booking> bookings;

  /// Optional callback when a booking inside this group is tapped.
  final Function(Booking)? onBookingTap;

  /// Optional callback when a booking inside this group is swiped to edit.
  final Function(Booking)? onModify;

  /// Optional callback when a booking inside this group is swiped to cancel/delete.
  final Function(Booking)? onDelete;

  /// Optional counter to force closing all slidable items.
  final int slidableResetCounter;

  /// Creates a [VendorBookingGroup].
  const VendorBookingGroup({
    super.key,
    required this.vendor,
    required this.bookings,
    this.onBookingTap,
    this.onModify,
    this.onDelete,
    this.slidableResetCounter = 0,
  });

  List<DateTime> _getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      dates.add(current);
      current = DateTime(current.year, current.month, current.day + 1);
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    // Flatten multi-day bookings into individual daily bookings
    final List<Booking> flattenedBookings = [];
    for (final booking in bookings) {
      final dates = _getDatesInRange(booking.startDate, booking.endDate);
      if (dates.isEmpty) {
        flattenedBookings.add(booking);
      } else {
        for (final date in dates) {
          flattenedBookings.add(booking.copyWith(
            date: date,
            endDate: date,
          ));
        }
      }
    }

    return DarkHeaderCard(
      title: vendor.name,
      action: Text(
        vendor.id,
        style: AppTypography.labelCaps.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(flattenedBookings.length, (index) {
          final booking = flattenedBookings[index];
          final isLast = index == flattenedBookings.length - 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookingListItem(
                key: ValueKey('${booking.id}_${booking.startDate.millisecondsSinceEpoch}_$slidableResetCounter'),
                booking: booking,
                onTap: onBookingTap != null ? () => onBookingTap!(booking) : null,
                onModify: onModify != null ? () => onModify!(booking) : null,
                onDelete: onDelete != null ? () => onDelete!(booking) : null,
              ),
              if (!isLast)
                const Divider(
                  color: AppColors.outlineVariant,
                  height: 1,
                  thickness: 1,
                ),
            ],
          );
        }),
      ),
    );
  }
}
