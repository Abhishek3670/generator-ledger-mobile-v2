import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';
import '../providers/system_health_provider.dart';
import '../widgets/health_metric_card.dart';

class SystemHealthScreen extends ConsumerWidget {
  const SystemHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(systemHealthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SYSTEM HEALTH',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(systemHealthProvider.notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Metrics refreshed')),
              );
            },
          ),
        ],
      ),
      drawer: SideNavigationDrawer(
        currentRoute: '/admin/health',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: 'Abhishek Sharma',
        userRole: 'Fleet Manager',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'MONITOR',
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Live Server Metrics',
                style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Live CPU, memory, and temperature with real-time charts.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Status Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'APPLICATION STATUS',
                              style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    health.isHealthy ? 'Healthy' : 'Attention',
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.success, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'LAST CHECKED',
                              style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${health.lastChecked.month}/${health.lastChecked.day}/${health.lastChecked.year}, '
                              '${health.lastChecked.hour.toString().padLeft(2, '0')}:${health.lastChecked.minute.toString().padLeft(2, '0')}:${health.lastChecked.second.toString().padLeft(2, '0')}',
                              style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: AppColors.surfaceContainer, height: 1),
                    ),
                    Text(
                      'DATABASE CONNECTION',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        health.dbConnection,
                        style: AppTypography.bodySmall.copyWith(fontFamily: 'Courier', color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // CPU Usage Card
              HealthMetricCard(
                title: 'CPU USAGE',
                value: '${health.cpu.toStringAsFixed(1)}%',
                description: 'System-wide CPU utilization.',
                statusText: 'NORMAL',
                lineColor: AppColors.primary,
                points: health.cpuTrend,
                timeStart: '12:32:09',
                timeEnd: '12:32:27',
              ),
              const SizedBox(height: 16),

              // Memory Usage Card
              HealthMetricCard(
                title: 'MEMORY USAGE',
                value: '${health.memory.toStringAsFixed(1)}%',
                description: 'Used 923.9 MB / Total 7,281.5 MB',
                statusText: 'NORMAL',
                lineColor: AppColors.primary,
                points: health.memoryTrend,
                timeStart: '12:32:09',
                timeEnd: '12:32:27',
              ),
              const SizedBox(height: 16),

              // Temperature Card
              HealthMetricCard(
                title: 'TEMPERATURE',
                value: '${health.temperature.toStringAsFixed(1)}°C',
                description: 'Sensor: k10temp',
                statusText: 'NORMAL',
                lineColor: AppColors.danger,
                points: health.temperatureTrend,
                timeStart: '12:32:09',
                timeEnd: '12:32:27',
              ),
              const SizedBox(height: 16),

              // Build Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUILD INFO',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Title:',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Generator Booking Ledger',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Version:',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          health.appVersion,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
