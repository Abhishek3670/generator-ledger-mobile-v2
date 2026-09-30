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

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return const SizedBox.shrink();

    final List<Booking> dateGroupBookings = [];
    for (final booking in bookings) {
      final grouped = booking.groupItemsByDate();
      for (final entry in grouped.entries) {
        final dateKey = entry.key;
        final dateItems = entry.value;
        final date = DateTime.tryParse(dateKey) ?? booking.startDate;

        final dateGenerators = dateItems.map((item) => item.generatorId).toList();
        final double dateCapacityKva = dateItems.fold(0.0, (sum, item) => sum + (item.capacityKva ?? 0.0));
        final isWhole = dateCapacityKva.truncateToDouble() == dateCapacityKva;
        final dateCapacityStr = '${dateCapacityKva.toStringAsFixed(isWhole ? 0 : 1)} kVA';

        final distinctStatuses = dateItems.map((item) => item.itemStatus.trim()).where((s) => s.isNotEmpty).toSet();
        final dateStatus = distinctStatuses.length == 1 ? distinctStatuses.first : booking.status;

        dateGroupBookings.add(booking.copyWith(
          generators: dateGenerators,
          capacity: dateCapacityStr,
          date: date,
          endDate: date,
          status: dateStatus,
          items: dateItems,
        ));
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
        children: List.generate(dateGroupBookings.length, (index) {
          final booking = dateGroupBookings[index];
          final isLast = index == dateGroupBookings.length - 1;

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
