import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';

/// A card widget supporting various levels of custom elevations (Level 0 -> Level 5).
class ElevatedCard extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The elevation level (0 to 5).
  final int elevation;

  /// Corner radius of the card border.
  final double borderRadius;

  /// Card background color. Defaults to [AppColors.surface].
  final Color? backgroundColor;

  /// Creates an [ElevatedCard].
  const ElevatedCard({
    super.key,
    required this.child,
    this.elevation = 1,
    this.borderRadius = 16.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = _getShadowForElevation(elevation);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: elevation == 0
            ? Border.all(color: AppColors.border, width: 1)
            : null,
        boxShadow: shadows,
      ),
      child: child,
    );
  }

  List<BoxShadow> _getShadowForElevation(int level) {
    switch (level) {
      case 0:
        return AppElevation.level0;
      case 1:
        return AppElevation.level1;
      case 2:
        return AppElevation.level2;
      case 3:
        return AppElevation.level3;
      case 4:
        return AppElevation.level4;
      case 5:
        return AppElevation.level5;
      default:
        return AppElevation.level1;
    }
  }
}
