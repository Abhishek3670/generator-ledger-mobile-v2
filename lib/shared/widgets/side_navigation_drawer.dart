import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum SideNavigationDrawerVariant { light, dark }
enum SideNavigationDrawerContext { dashboard, operational }

/// A side navigation drawer with support for dark/light themes.
///
/// Features a dark slate theme (default) or light theme variant, user profile header,
/// operational route navigation links, and settings/logout bottom action buttons.
class SideNavigationDrawer extends StatelessWidget {
  /// The variant of the drawer (light or dark).
  final SideNavigationDrawerVariant variant;

  /// The context of the drawer (dashboard, operational, or admin).
  final SideNavigationDrawerContext? drawerContext;

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
    this.variant = SideNavigationDrawerVariant.dark,
    this.drawerContext,
    required this.currentRoute,
    required this.onNavigate,
    this.onSettingsPressed,
    this.onLogoutPressed,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
  });

  SideNavigationDrawerContext _deriveContext(String route, SideNavigationDrawerVariant varOption) {
    if (route == '/dashboard') {
      return SideNavigationDrawerContext.dashboard;
    }
    if (varOption == SideNavigationDrawerVariant.light) {
      return SideNavigationDrawerContext.dashboard;
    }
    return SideNavigationDrawerContext.operational;
  }

  @override
  Widget build(BuildContext context) {
    final activeContext = drawerContext ?? _deriveContext(currentRoute, variant);
    final isLight = activeContext == SideNavigationDrawerContext.dashboard;
    final isAdminRoute = currentRoute.startsWith('/admin');

    return Drawer(
      width: 280,
      backgroundColor: isLight ? Colors.white : AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header User Profile Area
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isLight ? AppColors.surface : Colors.transparent,
                border: isLight
                    ? const Border(bottom: BorderSide(color: AppColors.border, width: 1))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isLight ? AppColors.primary : AppColors.accent,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                        child: avatarUrl == null
                            ? Text(
                                userName.substring(0, 1).toUpperCase(),
                                style: AppTypography.headlineSmall.copyWith(
                                  color: isLight ? Colors.white : AppColors.primary,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isLight ? AppColors.primary : Colors.white,
                              ),
                            ),
                            if (userRole.isNotEmpty)
                              Text(
                                isLight ? userRole.toUpperCase() : userRole,
                                style: isLight
                                    ? AppTypography.labelCaps.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      )
                                    : AppTypography.bodySmall.copyWith(
                                        color: Colors.white70,
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isLight) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Genset Ledger',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isLight) const Divider(color: Colors.white24, height: 1),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: _buildNavLinks(context, activeContext),
              ),
            ),

            Divider(color: isLight ? AppColors.border : Colors.white24, height: 1),

            // Bottom Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (onSettingsPressed != null) onSettingsPressed!();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        child: Row(
                          children: [
                            Icon(
                              isAdminRoute ? Icons.dashboard_outlined : Icons.settings_outlined,
                              color: isLight ? AppColors.textSecondary : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isAdminRoute ? 'Exit Admin' : 'Settings',
                              style: AppTypography.bodySmall.copyWith(
                                color: isLight ? AppColors.textSecondary : Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onLogoutPressed != null) onLogoutPressed!();
                    },
                    icon: Icon(
                      Icons.logout,
                      color: isLight ? AppColors.danger : Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Logout',
                    style: isLight
                        ? IconButton.styleFrom(
                            hoverColor: AppColors.dangerBg,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavLinks(BuildContext context, SideNavigationDrawerContext activeContext) {
    if (activeContext == SideNavigationDrawerContext.dashboard) {
      return [
        _buildLightNavLink(
          context: context,
          icon: Icons.receipt_long_outlined,
          label: 'Billing Preview',
          routePath: '/billing',
        ),
      ];
    } else {
      return [
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
      ];
    }
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

  Widget _buildLightNavLink({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String routePath,
  }) {
    final isSelected = currentRoute == routePath;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onNavigate(routePath);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
