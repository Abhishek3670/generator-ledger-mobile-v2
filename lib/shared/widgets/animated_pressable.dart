import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/haptic_service.dart';

/// A wrapper widget that provides a micro-interactive scale animation (default 0.95x)
/// combined with a custom Material ripple effect and automatic light haptic feedback on tap.
class AnimatedPressable extends StatefulWidget {
  /// The widget to apply the animation to.
  final Widget child;

  /// Callback triggered when the pressable is tapped.
  final VoidCallback? onTap;

  /// The target scale when pressed.
  final double scaleFactor;

  /// The duration of the scale animation.
  final Duration duration;

  /// The border radius for the ripple effect shape.
  final BorderRadius? borderRadius;

  /// Creates an [AnimatedPressable].
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.borderRadius,
  });

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.light();
            widget.onTap!();
          },
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          borderRadius: widget.borderRadius,
          splashColor: AppColors.primary.withValues(alpha: 0.20),
          highlightColor: AppColors.primary.withValues(alpha: 0.10),
          child: widget.child,
        ),
      ),
    );
  }
}
