import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/reminder_offset.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/reminder_picker_sheet.dart';

class BookingDetailModal extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final bool isVisible;
  final ReminderOffset? initialReminderOffset;
  final VoidCallback? onReminderTap;

  const BookingDetailModal({
    super.key,
    required this.booking,
    required this.onClose,
    required this.onEdit,
    this.isVisible = true,
    this.initialReminderOffset,
    this.onReminderTap,
  });

  @override
  ConsumerState<BookingDetailModal> createState() => _BookingDetailModalState();
}

class _BookingDetailModalState extends ConsumerState<BookingDetailModal> {
  ReminderOffset? _reminderOffset;
  bool _showReminderPicker = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReminderOffset != null) {
      _reminderOffset = widget.initialReminderOffset;
    } else {
      _loadReminderStatus();
    }
  }

  @override
  void didUpdateWidget(BookingDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialReminderOffset != oldWidget.initialReminderOffset) {
      setState(() {
        _reminderOffset = widget.initialReminderOffset;
      });
    } else if (widget.booking.id != oldWidget.booking.id) {
      setState(() {
        _loadReminderStatus();
      });
    }
  }

  void _loadReminderStatus() {
    try {
      final reminderService = ref.read(bookingReminderServiceProvider);
      final globalSettings = ref.read(globalReminderSettingsProvider);
      _reminderOffset = reminderService.getReminder(
        widget.booking.id,
        widget.booking,
        globalSettings,
      );
    } catch (_) {
      _reminderOffset = null;
    }
  }

  void _openReminderPicker() {
    if (widget.onReminderTap != null) {
      widget.onReminderTap!();
      return;
    }
    setState(() {
      _showReminderPicker = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final hasReminder = _reminderOffset != null && _reminderOffset != ReminderOffset.none;
    final tooltipText = hasReminder
        ? 'Reminder: ${_reminderOffset!.displayLabel}'
        : 'Set Reminder';

    return Stack(
      children: [
        DraggableFormSheet(
          title: widget.booking.vendorName,
          category: 'bookings',
          onClose: widget.onClose,
          actions: [
            IconButton(
              key: const Key('booking-detail-reminder-button'),
              onPressed: _openReminderPicker,
              icon: Icon(
                hasReminder ? Icons.notifications_active : Icons.notification_add_outlined,
                color: hasReminder ? AppColors.accent : AppColors.textSecondary,
                size: 22,
              ),
              tooltip: tooltipText,
            ),
            IconButton(
              onPressed: widget.onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
              tooltip: 'Edit Booking',
            ),
          ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Details Grid (Status, Booked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRowDetail('STATUS', StatusBadge(label: widget.booking.status, type: _getStatusType(widget.booking.status))),
                _buildRowDetail('BOOKED', Text(DateFormat('yyyy-MM-dd').format(widget.booking.date), style: AppTypography.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assigned Generators
          Text('ASSIGNED GENERATORS', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildGeneratorsTable(),
            ),
          ),
        ],
      ),
    ),
    if (_showReminderPicker)
      ReminderPickerSheet(
        bookingId: widget.booking.id,
        bookingDate: widget.booking.date,
        vendorName: widget.booking.vendorName,
        initialOffset: _reminderOffset ?? ReminderOffset.none,
        onClose: () => setState(() => _showReminderPicker = false),
        onReminderSaved: (offset) {
          setState(() {
            _reminderOffset = offset == ReminderOffset.none ? ReminderOffset.none : offset;
            _showReminderPicker = false;
          });
        },
      ),
  ],
);
  }

  Widget _buildRowDetail(String label, Widget content) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        content,
      ],
    );
  }

  StatusBadgeType _getStatusType(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return StatusBadgeType.confirmed;
      case 'cancelled':
        return StatusBadgeType.cancelled;
      default:
        return StatusBadgeType.pending;
    }
  }

  Widget _buildGeneratorsTable() {
    final grouped = widget.booking.groupItemsByDate();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text('DATE', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
              SizedBox(width: 200, child: Text('GENERATORS', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
              SizedBox(width: 100, child: Text('CAPACITY', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
              SizedBox(width: 140, child: Text('STATUS', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
              SizedBox(width: 100, child: Text('REM', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        ...grouped.entries.expand((entry) {
          final date = entry.key;
          return entry.value.map((item) {
            final capacityStr = item.capacityKva != null ? '${item.capacityKva} kVA' : '—';
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text(date, style: AppTypography.bodySmall)),
                  SizedBox(width: 200, child: Text(item.generatorId, style: AppTypography.bodySmall.copyWith(color: item.isEmergency ? AppColors.danger : null), overflow: TextOverflow.ellipsis)),
                  SizedBox(width: 100, child: Text(capacityStr, style: AppTypography.bodySmall)),
                  SizedBox(width: 140, child: Align(alignment: Alignment.centerLeft, child: StatusBadge(label: item.itemStatus, type: _getStatusType(item.itemStatus)))),
                  SizedBox(width: 100, child: Text(item.remarks.isEmpty ? '-' : item.remarks, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          });
        }),
      ],
    );
  }
}
