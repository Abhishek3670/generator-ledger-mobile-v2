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
    final isIdSelected = currentMode == 'id';
    final isCapacitySelected = currentMode == 'capacity';

    return Row(
      children: [
        // Assign by Generator ID
        Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged('id'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isIdSelected ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: isIdSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Assign by Generator ID',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isIdSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Assign by Capacity (Auto-assign)
        Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged('capacity'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isCapacitySelected ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: isCapacitySelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Assign by Capacity (Auto-assign)',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isCapacitySelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
