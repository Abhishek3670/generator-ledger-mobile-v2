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

  /// Creates a [VendorBookingGroup].
  const VendorBookingGroup({
    super.key,
    required this.vendor,
    required this.bookings,
    this.onBookingTap,
    this.onModify,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();

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
        children: List.generate(bookings.length, (index) {
          final booking = bookings[index];
          final isLast = index == bookings.length - 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookingListItem(
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
