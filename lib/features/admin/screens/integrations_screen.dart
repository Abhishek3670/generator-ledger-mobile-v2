import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';
import '../../auth/providers/auth_provider.dart';

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: SideNavigationDrawer(
        currentRoute: '/admin/integrations',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: currentUser?.username ?? 'Guest',
        userRole: currentUser?.role ?? '',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Coming Soon',
                    style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This integration module is currently under development for the industrial ledger system.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
