import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A dark side navigation drawer for global navigation menu access.
///
/// Features a dark slate theme, a user profile header, operational route navigation links,
/// and settings/logout bottom action buttons.
class SideNavigationDrawer extends StatelessWidget {
  /// The currently active route name or path.
  final String currentRoute;

  /// Callback triggered when a navigation link is tapped.
  final void Function(String routePath) onNavigate;

  /// Callback triggered when settings is pressed.
  final VoidCallback? onSettingsPressed;

  /// Callback triggered when logout is pressed.
  final VoidCallback? onLogoutPressed;

  /// The user's name.
  final String userName;

  /// The user's role (e.g. "Fleet Manager", "Operator").
  final String userRole;

  /// Optional avatar image URL or asset path.
  final String? avatarUrl;

  /// Creates a [SideNavigationDrawer].
  const SideNavigationDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.onSettingsPressed,
    this.onLogoutPressed,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header User Profile Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            userName.substring(0, 1).toUpperCase(),
                            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
                        ),
                        Text(
                          userRole,
                          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildNavLink(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    label: 'DASHBOARD',
                    routePath: '/dashboard',
                  ),
                  _buildNavLink(
                    context: context,
                    icon: Icons.assignment_outlined,
                    label: 'BOOKINGS',
                    routePath: '/bookings',
                  ),
                  _buildNavLink(
                    context: context,
                    icon: Icons.electric_bolt_outlined,
                    label: 'GENSETS',
                    routePath: '/generators',
                  ),
                  _buildNavLink(
                    context: context,
                    icon: Icons.business_outlined,
                    label: 'VENDORS',
                    routePath: '/vendors',
                  ),
                  _buildNavLink(
                    context: context,
                    icon: Icons.analytics_outlined,
                    label: 'BILLING PREVIEW',
                    routePath: '/billing',
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // Bottom Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onSettingsPressed,
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                    label: Text(
                      'SETTINGS',
                      style: AppTypography.labelCaps.copyWith(color: Colors.white70),
                    ),
                  ),
                  IconButton(
                    onPressed: onLogoutPressed,
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String routePath,
  }) {
    final isSelected = currentRoute == routePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        onTap: () {
          Navigator.pop(context); // close drawer first
          onNavigate(routePath);
        },
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.white70,
        ),
        title: Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.accent,
        shape: const StadiumBorder(),
      ),
    );
  }
}
