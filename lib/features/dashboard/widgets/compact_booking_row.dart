import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/reminder_offset.dart';
import '../../../shared/widgets/status_badge.dart';

/// A compact row displaying booking details for the daily bookings list.
class CompactBookingRow extends ConsumerWidget {
  /// The booking data to display.
  final Booking booking;

  /// Callback when the row is tapped.
  final VoidCallback? onTap;

  /// Optional override for whether a reminder is active.
  final bool? hasReminder;

  /// Creates a [CompactBookingRow].
  const CompactBookingRow({
    super.key,
    required this.booking,
    this.onTap,
    this.hasReminder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool activeReminder = false;
    if (hasReminder != null) {
      activeReminder = hasReminder!;
    } else {
      try {
        final reminderService = ref.watch(bookingReminderServiceProvider);
        final offset = reminderService.getReminder(booking.bookingId);
        activeReminder = offset != null && offset != ReminderOffset.none;
      } catch (_) {
        activeReminder = false;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.vendorName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: booking.status.toUpperCase(),
                        type: _getStatusBadgeType(booking.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'ID: ${booking.bookingId}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (activeReminder) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.notifications_active,
                          size: 13,
                          color: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.electric_bolt, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        booking.generatorId,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
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
