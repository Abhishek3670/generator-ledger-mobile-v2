import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/modal_scaffold.dart';
import '../../../shared/models/vendor.dart';

class VendorActionMenu extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isVisible;

  const VendorActionMenu({
    super.key,
    required this.vendor,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'ACTIONS: ${vendor.name.toUpperCase()}',
      isVisible: isVisible,
      onClose: onClose,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: Text('Edit Vendor', style: AppTypography.bodyMedium),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () {
              onClose();
              onEdit();
            },
          ),
          const Divider(height: 1, color: AppColors.surfaceContainer),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.danger),
            title: Text('Delete Vendor', style: AppTypography.bodyMedium.copyWith(color: AppColors.danger)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () {
              onClose();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
