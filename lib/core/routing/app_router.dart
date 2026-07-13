import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_storage.dart';
import '../services/deep_link_service.dart';
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
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../navigation/page_transitions.dart';
import 'route_names.dart';


/// Full router configuration for the application.
abstract final class AppRouter {
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  static final _authRefresh = _AuthRefreshNotifier();
  static TokenStorage tokenStorage = TokenStorage();

  /// The [DeepLinkService] instance, initialized after the router is created.
  /// Accessible so external code (e.g., main.dart) can call [init] on it.
  static late final DeepLinkService deepLinkService;

  /// Whether [deepLinkService] has been initialized.
  static bool _deepLinkServiceInitialized = false;

  /// Initialize the deep link service. Must be called once after app startup.
  static Future<void> initDeepLinks() async {
    if (_deepLinkServiceInitialized) return;
    deepLinkService = DeepLinkService(router: router);
    await deepLinkService.init();
    _deepLinkServiceInitialized = true;
  }

  static void refreshAuthState() {
    _authRefresh.refresh();
  }

  /// Global router declaration using [GoRouter] and stateful nested navigation.
  static final router = GoRouter(
    initialLocation: '/dashboard',
    observers: [routeObserver],
    refreshListenable: _authRefresh,
    redirect: (context, state) async {
      final token = await tokenStorage.getToken();
      final isAuthenticated = token != null && token.isNotEmpty;
      final isLoggingIn = state.matchedLocation == '/login';
      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) {
        // After login, check if a deep link arrived while unauthenticated.
        if (_deepLinkServiceInitialized) {
          final pending = deepLinkService.consumePendingDeepLink();
          if (pending != null) return pending;
        }
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        pageBuilder: (context, state) => SlideRightTransitionPage<void>(
          key: state.pageKey,
          swipeBack: false,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/billing',
        name: RouteNames.billing,
        pageBuilder: (context, state) => SlideRightTransitionPage<void>(
          key: state.pageKey,
          child: const BillingPreviewScreen(),
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
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return SlideRightTransitionPage<void>(
                        key: state.pageKey,
                        child: GeneratorDetailScreen(generatorId: id),
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

class _AuthRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

class _OperationalShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _OperationalShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: SideNavigationDrawer(
        variant: SideNavigationDrawerVariant.light,
        drawerContext: SideNavigationDrawerContext.dashboard,
        currentRoute: _getRouteFromIndex(navigationShell.currentIndex),
        onNavigate: (routePath) {
          if (routePath == '/billing') {
            context.go(routePath);
          } else {
            final index = _getIndexFromRoute(routePath);
            if (index != -1) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            }
          }
        },
        userName: currentUser?.username ?? 'Guest',
        userRole: currentUser?.role ?? '',
        onSettingsPressed: () => context.go('/admin/health'),
        onLogoutPressed: () async {
          await ref.read(authProvider.notifier).logout();
          AppRouter.refreshAuthState();
          if (!context.mounted) {
            return;
          }
          context.go('/login');
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Genset',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
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

class _AdminShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _AdminShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: SideNavigationDrawer(
        variant: SideNavigationDrawerVariant.light,
        drawerContext: SideNavigationDrawerContext.dashboard,
        currentRoute: _getRouteFromIndex(navigationShell.currentIndex),
        onNavigate: (routePath) {
          if (routePath == '/billing' || routePath == '/dashboard') {
            context.go(routePath);
          } else {
            final index = _getIndexFromRoute(routePath);
            if (index != -1) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            }
          }
        },
        userName: currentUser?.username ?? 'Guest',
        userRole: currentUser?.role ?? '',
        onSettingsPressed: () => context.go('/dashboard'),
        onLogoutPressed: () async {
          await ref.read(authProvider.notifier).logout();
          AppRouter.refreshAuthState();
          if (!context.mounted) {
            return;
          }
          context.go('/login');
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Genset',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.border),
        ),
      ),
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

  String _getRouteFromIndex(int index) {
    switch (index) {
      case 0:
        return '/admin/health';
      case 1:
        return '/admin/users';
      case 2:
        return '/admin/integrations';
      default:
        return '/admin/health';
    }
  }

  int _getIndexFromRoute(String route) {
    switch (route) {
      case '/admin/health':
        return 0;
      case '/admin/users':
        return 1;
      case '/admin/integrations':
        return 2;
      default:
        return -1;
    }
  }
}
