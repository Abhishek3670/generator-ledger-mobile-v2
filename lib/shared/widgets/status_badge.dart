import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// Semantic status categories for status badges.
enum StatusBadgeType {
  /// Confirmed status (e.g. Booking Confirmed)
  confirmed,

  /// Active status (e.g. Running, Live)
  active,

  /// Pending status (e.g. Awaiting Approval)
  pending,

  /// Cancelled, Offline, or Error status
  cancelled,
}

/// A pill-shaped status indicator badge.
///
/// Features prefix icons for accessibility and semantic theme colors matching status states.
class StatusBadge extends StatelessWidget {
  /// The text label to display on the badge.
  final String label;

  /// The type of status, determining color palette and leading icon.
  final StatusBadgeType type;

  /// Creates a [StatusBadge].
  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final IconData icon;

    switch (type) {
      case StatusBadgeType.confirmed:
        backgroundColor = AppColors.successLight;
        textColor = AppColors.successText;
        icon = Icons.check;
        break;
      case StatusBadgeType.active:
        backgroundColor = AppColors.infoLight;
        textColor = AppColors.infoText;
        icon = Icons.info_outline;
        break;
      case StatusBadgeType.pending:
        backgroundColor = AppColors.warningLight;
        textColor = AppColors.warningText;
        icon = Icons.access_time;
        break;
      case StatusBadgeType.cancelled:
        backgroundColor = AppColors.errorLight;
        textColor = AppColors.errorText;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelCaps.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
