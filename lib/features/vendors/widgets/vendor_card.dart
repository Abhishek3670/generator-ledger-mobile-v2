import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/swipe_action_card.dart';

import '../../../core/navigation/hero_tags.dart';

/// Card displaying details of a single vendor (name, ID, location, phone, accent border).
class VendorCard extends StatelessWidget {
  /// The vendor information to display.
  final Vendor vendor;

  /// Optional callback when vertical actions dropdown is clicked.
  final VoidCallback? onMorePressed;

  /// Optional callback when swipe-to-edit is triggered.
  final VoidCallback? onModify;

  /// Optional callback when swipe-to-delete is triggered.
  final VoidCallback? onDelete;

  /// Creates a [VendorCard].
  const VendorCard({
    super.key,
    required this.vendor,
    this.onMorePressed,
    this.onModify,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isRental = vendor.category == 'rental';

    final cardContent = Hero(
      tag: HeroTags.vendorCard(vendor.id),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Color(0x0D0F172A),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isRental)
                    Container(
                      width: 4,
                      color: AppColors.warning,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendor.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      vendor.id,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: onMorePressed,
                                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        vendor.location,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                    const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      vendor.phone,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

    return SwipeActionCard(
      onModify: onModify,
      onDelete: onDelete,
      child: cardContent,
    );
  }
}
