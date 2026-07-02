import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'modal_scaffold.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;
  final bool isVisible;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    this.confirmText = 'CONFIRM',
    this.cancelText = 'CANCEL',
    this.isDestructive = false,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: title,
      isVisible: isVisible,
      onClose: onCancel,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          message,
          style: AppTypography.bodyMedium,
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(cancelText, style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.danger : AppColors.accent,
              foregroundColor: isDestructive ? Colors.white : AppColors.primary,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(confirmText, style: AppTypography.labelCaps.copyWith(
              color: isDestructive ? Colors.white : AppColors.primary, 
              fontWeight: FontWeight.bold
            )),
          ),
        ],
      ),
    );
  }
}
