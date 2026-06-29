import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A dark-themed bottom navigation bar designed for administrative settings screens.
///
/// Features 3 tabs: Health, Users, and Integrations.
class AdminBottomNavBar extends StatelessWidget {
  /// The index of the currently selected tab.
  final int currentIndex;

  /// Callback triggered when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Creates an [AdminBottomNavBar].
  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.slate400,
      selectedLabelStyle: AppTypography.labelCaps.copyWith(color: AppColors.accent),
      unselectedLabelStyle: AppTypography.labelCaps.copyWith(color: AppColors.slate400),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.health_and_safety_outlined),
          activeIcon: Icon(Icons.health_and_safety),
          label: 'HEALTH',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'USERS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.extension_outlined),
          activeIcon: Icon(Icons.extension),
          label: 'INTEGRATIONS',
        ),
      ],
    );
  }
}
