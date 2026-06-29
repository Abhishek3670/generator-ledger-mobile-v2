import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A dark-themed bottom navigation bar designed for operational screens.
///
/// Features rounded top corners, backdrop blur, and pill-shaped active indicator for selected tab.
class AppBottomNavBar extends StatelessWidget {
  /// The index of the currently selected tab.
  final int currentIndex;

  /// Callback triggered when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Creates an [AppBottomNavBar].
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'DASHBOARD'),
      (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'BOOKINGS'),
      (icon: Icons.electric_bolt_outlined, activeIcon: Icons.electric_bolt, label: 'GENSET'),
      (icon: Icons.group_outlined, activeIcon: Icons.group, label: 'VENDORS'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.95), // Slate-900 with 95% opacity
            border: const Border(
              top: BorderSide(color: AppColors.primaryDark, width: 1), // Slate-800
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.tertiaryFixed : Colors.transparent,
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? AppColors.onTertiaryFixed : AppColors.slate400,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.onTertiaryFixed : AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
