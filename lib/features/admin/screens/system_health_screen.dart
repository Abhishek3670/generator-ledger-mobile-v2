import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/system_health_provider.dart';
import '../widgets/health_metric_card.dart';
import '../../../core/services/haptic_service.dart';

class SystemHealthScreen extends ConsumerStatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  ConsumerState<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends ConsumerState<SystemHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(systemHealthProvider.notifier).startPolling();
      }
    });
  }

  @override
  void deactivate() {
    ref.read(systemHealthProvider.notifier).stopPolling();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final healthAsync = ref.watch(systemHealthProvider);
    final connectivity = ref.watch(connectivityProvider);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            if (connectivity.value == ConnectivityResult.none) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  border: Border(bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.3))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: AppColors.warningText, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'No internet connection - Monitoring Offline',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warningText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: healthAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load system health',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(systemHealthProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (health) => SingleChildScrollView(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Live Server Metrics',
                              style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppColors.primary),
                            onPressed: () {
                              ref.read(systemHealthProvider.notifier).refresh();
                            },
                          ),
                        ],
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
                                    StatusBadge(
                                      label: health.isHealthy ? 'Healthy' : 'Warning',
                                      type: health.isHealthy ? StatusBadgeType.active : StatusBadgeType.pending,
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

                      // Preferences Card
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
                              'PREFERENCES',
                              style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Haptic Feedback',
                                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Provide tactile feedback for taps and actions.',
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: HapticService.isEnabled,
                                  activeThumbColor: AppColors.accent,
                                  activeTrackColor: AppColors.primary,
                                  onChanged: (value) async {
                                    await HapticService.setEnabled(value);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
