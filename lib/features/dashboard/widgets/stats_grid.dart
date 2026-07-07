import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/elevated_card.dart';

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
    return ElevatedCard(
      elevation: 1,
      borderRadius: AppDimensions.functionalRadius,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
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
      ),
    );
  }
}
