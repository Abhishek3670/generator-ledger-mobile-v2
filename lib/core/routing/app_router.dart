import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/admin_bottom_nav_bar.dart';
import '../../shared/widgets/app_bottom_nav_bar.dart';
import '../../shared/widgets/side_navigation_drawer.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Login Screen',
          showDrawer: false,
        ),
      ),
      GoRoute(
        path: '/billing',
        name: RouteNames.billing,
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Billing Preview',
          showDrawer: false,
        ),
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
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Dashboard Screen',
                  showDrawer: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                name: RouteNames.bookings,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Bookings Directory',
                  showDrawer: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/generators',
                name: RouteNames.generators,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Generators Directory',
                  showDrawer: true,
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: RouteNames.generatorDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return _PlaceholderScreen(
                        title: 'Generator Detail ID: $id',
                        showDrawer: false,
                      );
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
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Vendor Directory',
                  showDrawer: true,
                ),
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
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'System Health Monitor',
                  showDrawer: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                name: RouteNames.adminUsers,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'User Management',
                  showDrawer: true,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/integrations',
                name: RouteNames.adminIntegrations,
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Integrations Coming Soon',
                  showDrawer: true,
                ),
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final bool showDrawer;

  const _PlaceholderScreen({
    required this.title,
    required this.showDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTypography.headlineSmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: showDrawer
          ? SideNavigationDrawer(
              currentRoute: location,
              onNavigate: (routePath) {
                if (routePath == '/billing') {
                  context.push(routePath);
                } else if (routePath.startsWith('/admin')) {
                  context.go(routePath);
                } else {
                  context.go(routePath);
                }
              },
              userName: 'Abhishek Sharma',
              userRole: 'Fleet Manager',
            )
          : null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              'Route Location: $location',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            if (location == '/login') ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  AppRouter.isLoggedIn = true;
                  context.go('/dashboard');
                },
                child: const Text('Login Mock Action'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
