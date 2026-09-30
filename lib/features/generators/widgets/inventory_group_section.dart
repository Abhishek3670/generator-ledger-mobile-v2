import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/app_toast.dart';
import 'generator_card.dart';

/// Group section for generator inventory types with custom headers and borders.
class InventoryGroupSection extends StatefulWidget {
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

  /// Optional counter to force closing all slidable items.
  final int slidableResetCounter;

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
    this.slidableResetCounter = 0,
  });

  @override
  State<InventoryGroupSection> createState() => _InventoryGroupSectionState();
}

class _InventoryGroupSectionState extends State<InventoryGroupSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color countBadgeColor = AppColors.textSecondary;
    Color countBadgeBg = AppColors.surfaceContainer;
    Color titleColor = AppColors.primary;

    if (widget.category == 'permanent') {
      borderColor = AppColors.warning.withValues(alpha: 0.3);
      countBadgeColor = AppColors.warning;
      countBadgeBg = AppColors.warning.withValues(alpha: 0.1);
      titleColor = AppColors.warning;
    } else if (widget.category == 'emergency') {
      borderColor = AppColors.danger.withValues(alpha: 0.3);
      countBadgeColor = AppColors.danger;
      countBadgeBg = AppColors.danger.withValues(alpha: 0.1);
      titleColor = AppColors.danger;
    }

    const limit = 5;
    final showShowAll = !_isExpanded && widget.generators.length > limit;
    final visibleGenerators = showShowAll
        ? widget.generators.take(limit).toList()
        : widget.generators;

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
                    widget.title,
                    style: AppTypography.headlineSmall.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: widget.description,
                        type: ToastType.info,
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
                  '${widget.generators.length}',
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

          if (widget.generators.isEmpty)
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
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleGenerators.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final generator = visibleGenerators[index];
                return GeneratorCard(
                  key: ValueKey('${generator.id}_${widget.slidableResetCounter}'),
                  generator: generator,
                  onModify: widget.onModify != null ? () => widget.onModify!(generator) : null,
                  onDelete: widget.onDelete != null ? () => widget.onDelete!(generator) : null,
                  onTap: widget.onGeneratorTap != null ? () => widget.onGeneratorTap!(generator) : null,
                );
              },
            ),
            if (showShowAll) ...[
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border, width: 1),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text(
                    'Show all ${widget.generators.length} →',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
