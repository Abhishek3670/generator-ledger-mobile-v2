import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/swipe_action_card.dart';

/// A list item showing booking schedule details (date, status, generator ID, capacity).
class BookingListItem extends StatelessWidget {
  /// The booking data for this item.
  final Booking booking;

  /// Optional callback when item is tapped.
  final VoidCallback? onTap;

  /// Optional callback when swipe-to-edit is triggered.
  final VoidCallback? onModify;

  /// Optional callback when swipe-to-cancel is triggered.
  final VoidCallback? onDelete;

  /// Creates a [BookingListItem].
  const BookingListItem({
    super.key,
    required this.booking,
    this.onTap,
    this.onModify,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusType = _getStatusBadgeType(booking.status);
    final dateString = booking.formatBookingDate();
    final generatorItems = booking.parseGeneratorItems();
    final isConfirmed = booking.status.toLowerCase() == 'confirmed';

    final cardContent = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: 'booking-card-${booking.id}-${booking.startDate.millisecondsSinceEpoch}',
        child: Material(
          color: Colors.transparent,
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
                      label: isConfirmed ? '' : booking.status.toUpperCase(),
                      type: statusType,
                      iconOnly: isConfirmed,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...generatorItems.map((item) {
                  final genId = item['id'] ?? '';
                  final matchingItem = booking.items.firstWhere(
                    (it) => it.generatorId == genId,
                    orElse: () => BookingItem(
                      generatorId: genId,
                      startDt: booking.formatBookingDate(),
                      itemStatus: '',
                      isEmergency: genId.toUpperCase().contains('EMERGENCY') || genId.toUpperCase().contains('HA'),
                      remarks: '',
                    ),
                  );
                  final isEmergency = matchingItem.isEmergency;
                  final itemColor = isEmergency ? AppColors.danger : AppColors.primary;
                  final capacityColor = isEmergency ? AppColors.danger : AppColors.textSecondary;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium.copyWith(color: itemColor),
                        children: [
                          TextSpan(
                            text: genId,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '(${item['capacity']})',
                            style: AppTypography.bodyMedium.copyWith(color: capacityColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );

    return SwipeActionCard(
      itemId: '${booking.id}_${booking.startDate.millisecondsSinceEpoch}',
      onModify: onModify,
      onDelete: onDelete,
      deleteLabel: 'Cancel',
      deleteIcon: Icons.cancel_outlined,
      child: cardContent,
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
