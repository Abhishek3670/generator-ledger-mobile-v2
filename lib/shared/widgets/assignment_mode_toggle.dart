import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A reusable toggle switch for selecting assignment modes.
class AssignmentModeToggle extends StatelessWidget {
  final String currentMode; // e.g., 'id' or 'capacity'
  final ValueChanged<String> onModeChanged;

  const AssignmentModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => onModeChanged('id'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentMode == 'id' ? AppColors.primary : AppColors.surfaceContainer,
              foregroundColor: currentMode == 'id' ? Colors.white : AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('Generator ID', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onModeChanged('capacity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentMode == 'capacity' ? AppColors.primary : AppColors.surfaceContainer,
              foregroundColor: currentMode == 'capacity' ? Colors.white : AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('Capacity', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
