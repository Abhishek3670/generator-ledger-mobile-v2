import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/services/booking_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/reminder_offset.dart';
import '../../../shared/widgets/app_toast.dart';

/// Integrations tab screen hosting global Booking Reminder and Notification settings.
///
/// Features a master enable/disable switch and multi-select alarm-style checkboxes
/// for trigger intervals in accordance with the industrial design system.
class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  static const List<({ReminderOffset offset, String title, String badge})> _intervals = [
    (offset: ReminderOffset.thirtyMin, title: '30 minutes before', badge: '30m'),
    (offset: ReminderOffset.oneHour, title: '1 hour before', badge: '1h'),
    (offset: ReminderOffset.threeHours, title: '3 hours before', badge: '3h'),
    (offset: ReminderOffset.oneDay, title: '1 day before (24 hours)', badge: '24h'),
    (offset: ReminderOffset.twoDays, title: '2 days before (48 hours)', badge: '48h'),
    (offset: ReminderOffset.oneWeek, title: '1 week before (7 days)', badge: '7d'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(globalReminderSettingsProvider);
    final notifier = ref.read(globalReminderSettingsProvider.notifier);
    final reminderService = ref.read(bookingReminderServiceProvider);
    final bookings = ref.watch(bookingProvider).valueOrNull ?? [];

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Card
              _buildHeaderCard(),
              const SizedBox(height: 16),

              // 2. Master Switch Card
              _buildMasterSwitchCard(context, settings, notifier, reminderService, bookings),
              const SizedBox(height: 24),

              // 3. Trigger Intervals Section Header
              Text(
                'REMINDER INTERVALS (MULTI-SELECT)',
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select how far in advance you want to receive reminder alerts:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Multi-Select Interval Cards
              ..._intervals.map((item) {
                final isChecked = settings.selectedOffsets.contains(item.offset);
                return _buildIntervalCard(
                  context: context,
                  item: item,
                  isChecked: isChecked,
                  enabled: settings.enabled,
                  onChanged: (bool? value) async {
                    await notifier.toggleOffset(item.offset);
                    final updatedOffsets = Set<ReminderOffset>.from(settings.selectedOffsets);
                    if (updatedOffsets.contains(item.offset)) {
                      updatedOffsets.remove(item.offset);
                    } else {
                      updatedOffsets.add(item.offset);
                    }
                    final updatedSettings = settings.copyWith(selectedOffsets: updatedOffsets);
                    final count = await reminderService.resyncAllReminders(bookings, updatedSettings);
                    if (context.mounted) {
                      AppToast.show(
                        context,
                        message: 'Updated reminder intervals ($count scheduled)',
                        type: ToastType.success,
                      );
                    }
                  },
                );
              }),
              const SizedBox(height: 20),

              // 5. Informational Alert Container
              _buildInfoContainer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INTEGRATIONS / SETTINGS',
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking Reminders',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure automated reminders ahead of upcoming 24-hour generator bookings.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterSwitchCard(
    BuildContext context,
    GlobalReminderSettings settings,
    GlobalReminderSettingsNotifier notifier,
    BookingReminderService reminderService,
    List<Booking> bookings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: settings.enabled ? AppColors.accent : AppColors.border,
          width: settings.enabled ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: settings.enabled
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              settings.enabled
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: settings.enabled ? AppColors.primaryDark : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Booking Reminders',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  settings.enabled
                      ? 'Active alerts for upcoming bookings'
                      : 'All reminders disabled',
                  style: AppTypography.bodySmall.copyWith(
                    color: settings.enabled
                        ? AppColors.successText
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            key: const Key('master-reminder-switch'),
            value: settings.enabled,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.accent,
            onChanged: (bool newEnabled) async {
              await notifier.toggleEnabled(newEnabled);
              final updatedSettings = settings.copyWith(enabled: newEnabled);
              final scheduledCount =
                  await reminderService.resyncAllReminders(bookings, updatedSettings);
              if (context.mounted) {
                if (newEnabled) {
                  AppToast.show(
                    context,
                    message: 'Booking reminders enabled ($scheduledCount scheduled)',
                    type: ToastType.success,
                  );
                } else {
                  AppToast.show(
                    context,
                    message: 'All booking reminders disabled',
                    type: ToastType.info,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalCard({
    required BuildContext context,
    required ({ReminderOffset offset, String title, String badge}) item,
    required bool isChecked,
    required bool enabled,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          decoration: BoxDecoration(
            color: isChecked && enabled
                ? const Color(0xFFFFFBEB)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isChecked && enabled ? AppColors.accent : AppColors.border,
              width: isChecked && enabled ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? () => onChanged(!isChecked) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Checkbox(
                    key: Key('interval-checkbox-${item.offset.name}'),
                    value: isChecked,
                    activeColor: AppColors.primary,
                    checkColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: enabled ? onChanged : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: isChecked && enabled
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isChecked && enabled
                          ? AppColors.primary
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      item.badge,
                      style: AppTypography.labelCaps.copyWith(
                        color: isChecked && enabled
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoContainer() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              color: AppColors.accent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reminders are scheduled automatically on your device for all upcoming bookings. When enabled, each selected interval triggers an alert before the booking starts.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
