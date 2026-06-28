import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// A bottom-anchored action zone containing a pill-shaped search input and a circular Floating Action Button (FAB).
///
/// Designed to follow the ergonomic component structure of directories.
class FloatingSearchFAB extends StatelessWidget {
  /// Hint text displayed in the search input field.
  final String searchHint;

  /// Callback triggered when search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Icon to display in the FAB.
  final IconData fabIcon;

  /// Callback triggered when the FAB is pressed.
  final VoidCallback? onFABPressed;

  /// Optional text controller to manage search field state.
  final TextEditingController? controller;

  /// Creates a [FloatingSearchFAB].
  const FloatingSearchFAB({
    super.key,
    required this.searchHint,
    this.onSearchChanged,
    required this.fabIcon,
    this.onFABPressed,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.mobileGutter),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Color(0x0D0F172A),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 48,
            height: 48,
            child: FloatingActionButton(
              onPressed: onFABPressed,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const StadiumBorder(),
              child: Icon(fabIcon),
            ),
          ),
        ],
      ),
    );
  }
}
