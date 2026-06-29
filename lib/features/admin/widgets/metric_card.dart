import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? changeLabel;
  final bool? isPositive;
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.changeLabel,
    this.isPositive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color trendColor = AppColors.textSecondary;
    if (isPositive != null) {
      trendColor = isPositive! ? AppColors.success : AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: AppColors.shadowSoft,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
              if (icon != null) Icon(icon, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (isPositive != null)
                  Icon(
                    isPositive! ? Icons.arrow_upward : Icons.arrow_downward,
                    color: trendColor,
                    size: 14,
                  ),
                const SizedBox(width: 4),
                Text(
                  changeLabel!,
                  style: AppTypography.bodySmall.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
