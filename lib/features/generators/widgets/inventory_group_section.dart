import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import 'generator_card.dart';

/// Group section for generator inventory types with custom headers and borders.
class InventoryGroupSection extends StatelessWidget {
  /// Section title (e.g. "Retailer Genset").
  final String title;

  /// Explanatory info snippet.
  final String description;

  /// Inventory group category ('retailer', 'permanent', 'emergency').
  final String category;

  /// List of mock generators in this group.
  final List<MockGenerator> generators;

  /// Callback when a card is swiped to modify.
  final Function(MockGenerator)? onModify;

  /// Callback when a card is swiped to delete.
  final Function(MockGenerator)? onDelete;

  /// Callback when a card is tapped.
  final Function(MockGenerator)? onGeneratorTap;

  /// Creates an [InventoryGroupSection].
  const InventoryGroupSection({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.generators,
    this.onModify,
    this.onDelete,
    this.onGeneratorTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color countBadgeColor = AppColors.textSecondary;
    Color countBadgeBg = AppColors.surfaceContainer;
    Color titleColor = AppColors.primary;

    if (category == 'permanent') {
      borderColor = AppColors.warning.withValues(alpha: 0.3);
      countBadgeColor = AppColors.warning;
      countBadgeBg = AppColors.warning.withValues(alpha: 0.1);
      titleColor = AppColors.warning;
    } else if (category == 'emergency') {
      borderColor = AppColors.danger.withValues(alpha: 0.3);
      countBadgeColor = AppColors.danger;
      countBadgeBg = AppColors.danger.withValues(alpha: 0.1);
      titleColor = AppColors.danger;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Color(0x0D0F172A),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(description),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: Icon(Icons.info_outline, color: titleColor, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: countBadgeBg,
                  borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  '${generators.length}',
                  style: AppTypography.labelCaps.copyWith(
                    color: countBadgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (generators.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  'No records found.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: generators.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final generator = generators[index];
                return GeneratorCard(
                  generator: generator,
                  onModify: onModify != null ? () => onModify!(generator) : null,
                  onDelete: onDelete != null ? () => onDelete!(generator) : null,
                  onTap: onGeneratorTap != null ? () => onGeneratorTap!(generator) : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
