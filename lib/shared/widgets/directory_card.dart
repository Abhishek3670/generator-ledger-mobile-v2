import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// A standard card layout container for list directories.
///
/// Features a white background, 1px solid slate border, and support for an optional dark header.
class DirectoryCard extends StatelessWidget {
  /// The title text for the card header.
  final String? headerTitle;

  /// Optional subtitle text displayed in the header.
  final String? headerSubtitle;

  /// Optional action widget displayed on the right of the header.
  final Widget? headerAction;

  /// The body contents of the card.
  final Widget child;

  /// Whether the header row should be styled with a dark slate background.
  final bool hasDarkHeader;

  /// Creates a [DirectoryCard].
  const DirectoryCard({
    super.key,
    this.headerTitle,
    this.headerSubtitle,
    this.headerAction,
    required this.child,
    this.hasDarkHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = headerTitle;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.functionalBorderRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: AppColors.shadowSoft,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppDimensions.functionalBorderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hasDarkHeader ? AppColors.primary : AppColors.surface,
                  border: hasDarkHeader
                      ? null
                      : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.headlineSmall.copyWith(
                              color: hasDarkHeader ? Colors.white : AppColors.primary,
                            ),
                          ),
                          if (headerSubtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              headerSubtitle!,
                              style: AppTypography.bodySmall.copyWith(
                                color: hasDarkHeader ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (headerAction != null) ...[
                      const SizedBox(width: 8),
                      headerAction!,
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
