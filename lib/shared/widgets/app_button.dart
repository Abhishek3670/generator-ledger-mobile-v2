import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'animated_pressable.dart';

/// Button variants defined in the design guidelines.
enum AppButtonVariant {
  /// Primary action: Slate-900 (#0f172a) background, white text.
  primary,

  /// Accent / Create action: Amber-400 (#fbbf24) background, dark navy text.
  accent,

  /// Ghost / Secondary action: Transparent background, 1px Slate-200 border, slate text.
  ghost,
}

/// A custom theme-compliant button supporting transitions and loading states.
class AppButton extends StatelessWidget {
  /// The text label of the button.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The style variant of the button.
  final AppButtonVariant variant;

  /// Optional icon placed to the left of the label.
  final Widget? icon;

  /// Optional flag indicating a busy/loading state.
  final bool isLoading;

  /// Optional horizontal width behavior (expanded or intrinsic).
  final bool isFullWidth;

  /// Creates an [AppButton].
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5);
        textColor = Colors.white;
        border = null;
        break;
      case AppButtonVariant.accent:
        backgroundColor = isEnabled ? AppColors.accent : AppColors.accent.withValues(alpha: 0.5);
        textColor = AppColors.primary;
        border = null;
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = isEnabled ? const Color(0xFF475569) : const Color(0xFF475569).withValues(alpha: 0.5);
        border = Border.all(color: AppColors.border, width: 1);
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (isFullWidth) {
      content = SizedBox(
        width: double.infinity,
        child: content,
      );
    }

    return AnimatedPressable(
      onTap: isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(9999),
          border: border,
        ),
        child: content,
      ),
    );
  }
}
