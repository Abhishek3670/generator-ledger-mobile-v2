import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../shared/widgets/status_badge.dart';

/// A list item showing booking schedule details (date, status, generator ID, capacity).
class BookingListItem extends StatelessWidget {
  /// The mock booking data for this item.
  final MockBooking booking;

  /// Optional callback when item is tapped.
  final VoidCallback? onTap;

  /// Creates a [BookingListItem].
  const BookingListItem({
    super.key,
    required this.booking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusType = _getStatusBadgeType(booking.status);
    final dateString = DateFormat('yyyy-MM-dd').format(booking.date);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateString,
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
              StatusBadge(
                label: booking.status.toUpperCase(),
                type: statusType,
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
              children: [
                TextSpan(
                  text: booking.generatorId,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: '(${booking.capacity})',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
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
