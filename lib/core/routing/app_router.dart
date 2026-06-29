import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/admin_bottom_nav_bar.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';
import '../../features/vendors/screens/vendor_directory_screen.dart';
import '../../features/generators/screens/generators_directory_screen.dart';
import '../../features/bookings/screens/bookings_directory_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/billing/screens/billing_preview_screen.dart';
import '../../features/generators/screens/generator_detail_screen.dart';
import '../../features/admin/screens/system_health_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/admin/screens/integrations_screen.dart';
import 'route_names.dart';

/// Full router configuration for the application.
abstract final class AppRouter {
  /// Simple mock authentication state toggle.
  static bool isLoggedIn = true;

  /// Global router declaration using [GoRouter] and stateful nested navigation.
  static final router = GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/billing',
        name: RouteNames.billing,
        builder: (context, state) => const BillingPreviewScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _OperationalShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: RouteNames.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                name: RouteNames.bookings,
                builder: (context, state) => const BookingsDirectoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/generators',
                name: RouteNames.generators,
                builder: (context, state) => const GeneratorsDirectoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: RouteNames.generatorDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return GeneratorDetailScreen(generatorId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/vendors',
                name: RouteNames.vendors,
                builder: (context, state) => const VendorDirectoryScreen(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AdminShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/health',
                name: RouteNames.adminHealth,
                builder: (context, state) => const SystemHealthScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                name: RouteNames.adminUsers,
                builder: (context, state) => const UserManagementScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/integrations',
                name: RouteNames.adminIntegrations,
                builder: (context, state) => const IntegrationsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _OperationalShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _OperationalShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _AdminShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}


