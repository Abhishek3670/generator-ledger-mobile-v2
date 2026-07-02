import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// A reusable widget for selecting generator capacities via chips.
class CapacityChipSelector extends StatelessWidget {
  final List<String> capacities;
  final String selectedCapacity;
  final ValueChanged<String> onCapacitySelected;

  const CapacityChipSelector({
    super.key,
    this.capacities = const ['25', '50', '100', '250'],
    required this.selectedCapacity,
    required this.onCapacitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: capacities.map((cap) {
        final isSelected = selectedCapacity == cap;
        return GestureDetector(
          onTap: () => onCapacitySelected(cap),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
            ),
            child: Text(
              cap,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
