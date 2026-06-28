import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A structured section header widget.
///
/// Combines an uppercase spaced sub-label, a prominent headline title, and an optional body description.
class SectionHeader extends StatelessWidget {
  /// The uppercase label/category text displayed above the title.
  final String category;

  /// The main header title.
  final String title;

  /// Optional body copy description displayed below the title.
  final String? description;

  /// Whether to use [AppTypography.displayLarge] (otherwise defaults to [AppTypography.headlineMedium]).
  final bool useDisplayLg;

  /// Creates a [SectionHeader].
  const SectionHeader({
    super.key,
    required this.category,
    required this.title,
    this.description,
    this.useDisplayLg = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: useDisplayLg ? AppTypography.displayLarge : AppTypography.headlineMedium,
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          Text(
            description!,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
