import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/widgets/status_badge.dart';

class GeneratorDetailModal extends StatelessWidget {
  final MockGenerator generator;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final bool isVisible;

  const GeneratorDetailModal({
    super.key,
    required this.generator,
    required this.onClose,
    this.onEdit,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusType = generator.status.toLowerCase() == 'active'
        ? StatusBadgeType.active
        : StatusBadgeType.cancelled;

    return ModalScaffold(
      title: 'GENERATOR DETAILS',
      isVisible: isVisible,
      onClose: onClose,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  generator.id,
                  style: AppTypography.headlineSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              StatusBadge(
                label: generator.status.toUpperCase(),
                type: statusType,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),

          // Detail rows
          _buildDetailRow('CAPACITY', generator.capacity),
          const SizedBox(height: 16),
          _buildDetailRow('TYPE', generator.type),
          const SizedBox(height: 16),
          _buildDetailRow('CATEGORY', generator.category.toUpperCase()),
          const SizedBox(height: 16),
          _buildDetailRow('ASSIGNED VENDOR', generator.assignedVendor ?? 'NONE'),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onClose,
            child: Text('CLOSE', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary)),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('EDIT', style: AppTypography.labelCaps.copyWith(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
