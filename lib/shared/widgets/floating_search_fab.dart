import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// A bottom-anchored action zone containing a pill-shaped search input and a circular Floating Action Button (FAB).
///
/// Designed to follow the ergonomic component structure of directories.
class FloatingSearchFAB extends StatefulWidget {
  /// Hint text displayed in the search input field.
  final String searchHint;

  /// Callback triggered when search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Icon to display in the FAB.
  final IconData? fabIcon;

  /// Callback triggered when the FAB is pressed.
  final VoidCallback? onFABPressed;

  /// A custom widget (e.g. ExpandableFABMenu) to display next to the search input.
  final Widget? actionWidget;

  /// Optional text controller to manage search field state.
  final TextEditingController? controller;

  /// Creates a [FloatingSearchFAB].
  const FloatingSearchFAB({
    super.key,
    required this.searchHint,
    this.onSearchChanged,
    this.fabIcon,
    this.onFABPressed,
    this.actionWidget,
    this.controller,
  });

  @override
  State<FloatingSearchFAB> createState() => _FloatingSearchFABState();
}

class _FloatingSearchFABState extends State<FloatingSearchFAB> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

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
                border: Border.all(
                  color: _isFocused ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  if (_isFocused)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 3,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    )
                  else
                    const BoxShadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: AppColors.shadowSoft,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  onChanged: widget.onSearchChanged,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
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
          if (widget.actionWidget != null) ...[
            const SizedBox(width: 16),
            widget.actionWidget!,
          ] else if (widget.fabIcon != null) ...[
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: widget.onFABPressed,
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primary,
              elevation: 4,
              shape: const StadiumBorder(),
              child: Icon(widget.fabIcon),
            ),
          ],
        ],
      ),
    );
  }
}
