import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A semi-transparent overlay with a backdrop blur filter.
///
/// Typically used to dim and blur the background when a modal or expandable menu is active.
class BackdropBlurOverlay extends StatelessWidget {
  /// Controls the visibility of the overlay.
  final bool isVisible;

  /// Optional callback when the overlay background is tapped.
  final VoidCallback? onTap;

  /// Optional child widget to render on top of the blurred overlay.
  final Widget? child;

  /// Optional opacity value for fading the backdrop blur.
  final double opacity;

  /// Creates a [BackdropBlurOverlay].
  const BackdropBlurOverlay({
    super.key,
    required this.isVisible,
    this.onTap,
    this.child,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: AppColors.primary.withValues(alpha: 0.40), // Slate-900 color at 40% opacity
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
