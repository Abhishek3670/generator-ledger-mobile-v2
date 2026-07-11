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
    final isIdMode = currentMode == 'id';

    return Row(
      children: [
        Text(
          isIdMode ? 'Assign by Generator ID' : 'Assign by Capacity',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Switch(
          value: isIdMode,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.border,
          onChanged: (value) => onModeChanged(value ? 'id' : 'capacity'),
        ),
      ],
    );
  }
}
