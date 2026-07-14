import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/status_badge.dart';

class BookingDetailModal extends StatelessWidget {
  final Booking booking;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final bool isVisible;

  const BookingDetailModal({
    super.key,
    required this.booking,
    required this.onClose,
    required this.onEdit,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return DraggableFormSheet(
      title: 'BOOKING',
      category: 'bookings',
      onClose: onClose,
      actions: [
        IconButton(
          onPressed: onEdit,
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
          // Header info
          Text(booking.vendorName, style: AppTypography.title),
          const SizedBox(height: 4),
          Text(booking.id, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Details Grid (Status, Created, Vendor ID, Booked)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDetailCol('STATUS', StatusBadge(label: booking.status, type: _getStatusType(booking.status)))),
                    Expanded(child: _buildDetailCol('CREATED', Text(DateFormat('yyyy-MM-dd\nHH:mm').format(DateTime.now()), style: AppTypography.bodySmall))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDetailCol('VENDOR ID', Text(booking.vendorId, style: AppTypography.bodySmall))),
                    Expanded(child: _buildDetailCol('BOOKED', Text(DateFormat('yyyy-MM-dd').format(booking.date), style: AppTypography.bodySmall))),
                  ],
                ),
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
    );
  }

  Widget _buildDetailCol(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
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
    final grouped = booking.groupItemsByDate();
    
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
              SizedBox(width: 100, child: Text('STATUS', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
              SizedBox(width: 100, child: Text('REM', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary))),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        ...grouped.entries.expand((entry) {
          final date = entry.key;
          return entry.value.map((item) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text(date, style: AppTypography.bodySmall)),
                  SizedBox(width: 200, child: Text(item.generatorId, style: AppTypography.bodySmall.copyWith(color: item.isEmergency ? AppColors.danger : null), overflow: TextOverflow.ellipsis)),
                  SizedBox(width: 100, child: Align(alignment: Alignment.centerLeft, child: StatusBadge(label: item.itemStatus, type: _getStatusType(item.itemStatus)))),
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
