import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../data/mock/mock_vendors.dart';

class DeleteVendorDialog extends StatelessWidget {
  final MockVendor vendor;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final bool isVisible;

  const DeleteVendorDialog({
    super.key,
    required this.vendor,
    required this.onClose,
    required this.onDelete,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'DELETE VENDOR',
      isVisible: isVisible,
      onClose: onClose,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Are you sure you want to delete vendor "${vendor.name}"?',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This action is permanent and cannot be undone.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onClose,
            child: Text('CANCEL', style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('DELETE', style: AppTypography.labelCaps.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
