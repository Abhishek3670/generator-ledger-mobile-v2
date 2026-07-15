import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/swipe_action_card.dart';
import '../../../shared/widgets/elevated_card.dart';

import '../../../core/navigation/hero_tags.dart';

/// Card component representing a single generator (genset) and its status.
class GeneratorCard extends StatelessWidget {
  /// The generator mock data.
  final MockGenerator generator;

  /// Optional callback when "Modify" swipe action is triggered.
  final VoidCallback? onModify;

  /// Optional callback when "Delete" swipe action is triggered.
  final VoidCallback? onDelete;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Creates a [GeneratorCard].
  const GeneratorCard({
    super.key,
    required this.generator,
    this.onModify,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Hero(
        tag: HeroTags.generatorCard(generator.id),
        child: ElevatedCard(
          elevation: 1,
          borderRadius: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  generator.id,
                  overflow: TextOverflow.visible,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    label: generator.status.toUpperCase(),
                    type: _getStatusBadgeType(generator.status),
                  ),
                  if (generator.bookingStatus != null) ...[
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: generator.bookingStatus!.toUpperCase(),
                      type: generator.bookingStatus!.toLowerCase() == 'booked'
                          ? StatusBadgeType.pending
                          : StatusBadgeType.confirmed,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cap: ${generator.capacity} | Type: ${(generator.type.isEmpty || generator.type == "-") ? "N/A" : generator.type}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          if (generator.category == 'permanent' && generator.assignedVendor != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'ASSIGNED TO: ',
                  style: AppTypography.labelCaps.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      generator.assignedVendor!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  ),
),
);

    return SwipeActionCard(
      itemId: generator.id,
      onModify: onModify,
      onDelete: onDelete,
      child: cardContent,
    );
  }

  StatusBadgeType _getStatusBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return StatusBadgeType.active;
      case 'maintenance':
        return StatusBadgeType.maintenance;
      case 'retired':
        return StatusBadgeType.retired;
      default:
        return StatusBadgeType.active;
    }
  }
}
