import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/swipe_action_card.dart';

import '../../../core/navigation/hero_tags.dart';

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
    final dateString = DateFormat('yyyy-MM-dd').format(booking.date);
    final generatorItems = _parseGeneratorItems();

    final cardContent = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: HeroTags.bookingCard(booking.id),
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
                      label: booking.status.toUpperCase(),
                      type: statusType,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...generatorItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                      children: [
                        TextSpan(
                          text: item['id'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: '(${item['capacity']})',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );

    return SwipeActionCard(
      onModify: onModify,
      onDelete: onDelete,
      deleteLabel: 'Cancel',
      deleteIcon: Icons.cancel_outlined,
      child: cardContent,
    );
  }

  List<Map<String, String>> _parseGeneratorItems() {
    return booking.generators.map((genId) {
      final match = RegExp(r'(\d+)kva', caseSensitive: false).firstMatch(genId);
      String capacity = match != null ? '${match.group(1)} kVA' : 'N/A';
      if (capacity == 'N/A' && booking.generators.length == 1) {
        capacity = booking.capacity;
      }
      return {'id': genId, 'capacity': capacity};
    }).toList();
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
