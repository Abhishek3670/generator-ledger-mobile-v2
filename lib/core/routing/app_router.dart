import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/side_navigation_drawer.dart';
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
import '../../features/auth/providers/auth_provider.dart';
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

class _OperationalShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _OperationalShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      drawer: SideNavigationDrawer(
        variant: navigationShell.currentIndex == 0
            ? SideNavigationDrawerVariant.light
            : SideNavigationDrawerVariant.dark,
        drawerContext: navigationShell.currentIndex == 0
            ? SideNavigationDrawerContext.dashboard
            : SideNavigationDrawerContext.operational,
        currentRoute: _getRouteFromIndex(navigationShell.currentIndex),
        onNavigate: (routePath) {
          final index = _getIndexFromRoute(routePath);
          if (index != -1) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          }
        },
        userName: currentUser?.username ?? 'Guest',
        userRole: currentUser?.role ?? '',
      ),
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

  String _getRouteFromIndex(int index) {
    switch (index) {
      case 0:
        return '/dashboard';
      case 1:
        return '/bookings';
      case 2:
        return '/generators';
      case 3:
        return '/vendors';
      default:
        return '/dashboard';
    }
  }

  int _getIndexFromRoute(String route) {
    switch (route) {
      case '/dashboard':
        return 0;
      case '/bookings':
        return 1;
      case '/generators':
        return 2;
      case '/vendors':
        return 3;
      default:
        return -1;
    }
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


