import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'metric_sparkline.dart';

class HealthMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final String statusText;
  final Color lineColor;
  final List<double> points;
  final String timeStart;
  final String timeEnd;

  const HealthMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.statusText,
    required this.lineColor,
    required this.points,
    required this.timeStart,
    required this.timeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(9999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(fontSize: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          MetricSparkline(
            points: points,
            lineColor: lineColor,
            timeStart: timeStart,
            timeEnd: timeEnd,
          ),
        ],
      ),
    );
  }
}
