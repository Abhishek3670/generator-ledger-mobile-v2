import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Horizontal 3-column stats summary panel displaying counters for bookings, gensets, and vendors.
class StatsGrid extends StatelessWidget {
  /// The total number of bookings.
  final int totalBookings;

  /// The total number of generators (gensets).
  final int totalGensets;

  /// The total number of vendors.
  final int totalVendors;

  /// Creates a [StatsGrid].
  const StatsGrid({
    super.key,
    required this.totalBookings,
    required this.totalGensets,
    required this.totalVendors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Bookings',
            value: '$totalBookings',
            subtext: '$totalBookings confirmed',
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Expanded(
          child: _buildStatCard(
            label: 'Gensets',
            value: '$totalGensets',
            subtext: '$totalGensets active',
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXs),
        Expanded(
          child: _buildStatCard(
            label: 'Vendors',
            value: '$totalVendors',
            subtext: '$totalVendors partners',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Color(0x0D0F172A),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
