import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A dark-themed bottom navigation bar designed for operational screens.
///
/// Features 4 tabs: Dashboard, Bookings, Genset, and Vendors.
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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTypography.labelCaps.copyWith(color: AppColors.accent),
      unselectedLabelStyle: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'DASHBOARD',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'BOOKINGS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.electric_bolt_outlined),
          activeIcon: Icon(Icons.electric_bolt),
          label: 'GENSET',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_outlined),
          activeIcon: Icon(Icons.business),
          label: 'VENDORS',
        ),
      ],
    );
  }
}
