import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// A reusable widget for selecting generator capacities via chips.
class CapacityChipSelector extends StatelessWidget {
  final List<String> capacities;
  final String? selectedCapacity;
  final List<String>? selectedCapacities;
  final ValueChanged<String>? onCapacitySelected;
  final ValueChanged<List<String>>? onCapacitiesChanged;
  final bool isMultiSelect;

  const CapacityChipSelector({
    super.key,
    this.capacities = const ['25', '50', '100', '250'],
    this.selectedCapacity,
    this.selectedCapacities,
    this.onCapacitySelected,
    this.onCapacitiesChanged,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: capacities.map((cap) {
        final isSelected = isMultiSelect
            ? (selectedCapacities?.contains(cap) ?? false)
            : selectedCapacity == cap;

        return GestureDetector(
          onTap: () {
            if (isMultiSelect) {
              if (onCapacitiesChanged != null) {
                final current = List<String>.from(selectedCapacities ?? []);
                if (current.contains(cap)) {
                  // Ensure at least one must be selected
                  if (current.length > 1) {
                    current.remove(cap);
                  }
                } else {
                  current.add(cap);
                }
                onCapacitiesChanged!(current);
              }
            } else {
              if (onCapacitySelected != null) {
                onCapacitySelected!(cap);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
            ),
            child: Text(
              isMultiSelect && !cap.endsWith('kVA') ? '$cap kVA' : cap,
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
