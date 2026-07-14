import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/status_badge.dart';

class GeneratorDetailModal extends StatelessWidget {
  final MockGenerator generator;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final bool isVisible;

  const GeneratorDetailModal({
    super.key,
    required this.generator,
    required this.onClose,
    required this.onEdit,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final statusType = _getStatusBadgeType(generator.status);

    return DraggableFormSheet(
      title: generator.id,
      category: 'generators',
      onClose: onClose,
      actions: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
          tooltip: 'Edit Generator',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Details Grid (Status, Capacity, Booking Status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildRowDetail(
                  'STATUS',
                  StatusBadge(
                    label: generator.status.toUpperCase(),
                    type: statusType,
                  ),
                ),
                _buildRowDetail(
                  'CAPACITY',
                  Text(generator.capacity, style: AppTypography.bodySmall),
                ),
                if (generator.bookingStatus != null)
                  _buildRowDetail(
                    'BOOKING',
                    StatusBadge(
                      label: generator.bookingStatus!.toUpperCase(),
                      type: generator.bookingStatus!.toLowerCase() == 'booked'
                          ? StatusBadgeType.pending
                          : StatusBadgeType.confirmed,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details List
          Text(
            'DETAILS',
            style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoDetail(
                  'TYPE',
                  (generator.type.isEmpty || generator.type == '-') ? 'N/A' : generator.type,
                ),
                const SizedBox(height: 16),
                _buildInfoDetail(
                  'CATEGORY',
                  generator.category[0].toUpperCase() + generator.category.substring(1),
                ),
                const SizedBox(height: 16),
                _buildInfoDetail(
                  'ASSIGNED VENDOR',
                  generator.assignedVendor ?? 'Unassigned',
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildInfoDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  StatusBadgeType _getStatusBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return StatusBadgeType.active;
      case 'maintenance':
        return StatusBadgeType.maintenance;
      case 'retired':
        return StatusBadgeType.retired;
      default:
        return StatusBadgeType.active;
    }
  }
}
