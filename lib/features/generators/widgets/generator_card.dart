import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/swipe_action_card.dart';

/// Card component representing a single generator (genset) and its status.
class GeneratorCard extends StatelessWidget {
  /// The generator mock data.
  final MockGenerator generator;

  /// Optional callback when "Modify" swipe action is triggered.
  final VoidCallback? onModify;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Creates a [GeneratorCard].
  const GeneratorCard({
    super.key,
    required this.generator,
    this.onModify,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Color(0x0D0F172A),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  generator.id,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const StatusBadge(
                label: 'Active',
                type: StatusBadgeType.active,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cap: ${generator.capacity} | Type: ${generator.type}',
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
    );

    if (generator.category == 'retailer') {
      return SwipeActionCard(
        onModify: onModify,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
