import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/reminder_offset.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';

/// A bottom sheet widget for selecting or updating a booking reminder offset.
///
/// Features a radio-style selection list of [ReminderOffset] values, design-system
/// compliant typography (Space Grotesk headers, Inter body), 8px functional radii,
/// 1px borders, and a pill-shaped Amber-400 CTA button.
class ReminderPickerSheet extends ConsumerStatefulWidget {
  /// The unique identifier of the booking.
  final String bookingId;

  /// The start date and time of the booking.
  final DateTime bookingDate;

  /// Optional vendor display name for notification content.
  final String? vendorName;

  /// The currently active reminder offset if one exists.
  final ReminderOffset initialOffset;

  /// Callback when a reminder offset is successfully saved or cancelled.
  final ValueChanged<ReminderOffset>? onReminderSaved;

  /// Callback to close or dismiss this sheet.
  final VoidCallback onClose;

  /// If true, wraps the sheet inside [DraggableFormSheet].
  /// If false, renders as a standalone bottom sheet container.
  final bool useDraggableSheet;

  const ReminderPickerSheet({
    super.key,
    required this.bookingId,
    required this.bookingDate,
    this.vendorName,
    this.initialOffset = ReminderOffset.none,
    this.onReminderSaved,
    required this.onClose,
    this.useDraggableSheet = true,
  });

  /// Helper method to present this picker as a modal bottom sheet.
  static Future<ReminderOffset?> show({
    required BuildContext context,
    required String bookingId,
    required DateTime bookingDate,
    String? vendorName,
    ReminderOffset initialOffset = ReminderOffset.none,
    ValueChanged<ReminderOffset>? onReminderSaved,
  }) {
    return showModalBottomSheet<ReminderOffset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReminderPickerSheet(
        bookingId: bookingId,
        bookingDate: bookingDate,
        vendorName: vendorName,
        initialOffset: initialOffset,
        useDraggableSheet: false,
        onClose: () => Navigator.of(ctx).pop(),
        onReminderSaved: onReminderSaved,
      ),
    );
  }

  @override
  ConsumerState<ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends ConsumerState<ReminderPickerSheet> {
  late ReminderOffset _selectedOffset;

  @override
  void initState() {
    super.initState();
    _selectedOffset = widget.initialOffset;
  }

  Future<void> _handleSave() async {
    final reminderService = ref.read(bookingReminderServiceProvider);

    if (_selectedOffset == ReminderOffset.none) {
      await reminderService.cancelReminder(widget.bookingId);
      if (mounted) {
        AppToast.show(
          context,
          message: 'Reminder cancelled',
          type: ToastType.info,
        );
        widget.onReminderSaved?.call(ReminderOffset.none);
        widget.onClose();
      }
      return;
    }

    final scheduledDate = widget.bookingDate.subtract(_selectedOffset.duration);
    if (scheduledDate.isBefore(DateTime.now())) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Reminder time is in the past and cannot be scheduled',
          type: ToastType.warning,
        );
      }
      return;
    }

    final success = await reminderService.setReminder(
      widget.bookingId,
      widget.bookingDate,
      _selectedOffset,
      vendorName: widget.vendorName,
    );

    if (mounted) {
      if (success) {
        AppToast.show(
          context,
          message: 'Reminder set for ${_selectedOffset.displayLabel}',
          type: ToastType.success,
        );
        widget.onReminderSaved?.call(_selectedOffset);
        widget.onClose();
      } else {
        AppToast.show(
          context,
          message: 'Failed to schedule reminder',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useDraggableSheet) {
      return DraggableFormSheet(
        title: 'Set Reminder',
        category: 'REMINDERS',
        onClose: widget.onClose,
        footer: _buildFooter(),
        child: _buildContent(),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
          left: BorderSide(color: AppColors.border, width: 1),
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REMINDERS',
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set Reminder',
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: _buildContent(),
                ),
              ),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'NOTIFICATION TIMING',
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.primary,
            letterSpacing: 2.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose when you would like to be reminded before the booking starts.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...ReminderOffset.values.map((offset) {
          final isSelected = _selectedOffset == offset;
          final label = offset == ReminderOffset.none ? 'No Reminder' : offset.displayLabel;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              key: Key('reminder-option-${offset.name}'),
              onTap: () {
                setState(() {
                  _selectedOffset = offset;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('reminder-set-button'),
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          'SET REMINDER',
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
