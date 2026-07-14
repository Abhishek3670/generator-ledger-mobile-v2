import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import 'vendor_card.dart';

class VendorGroupSection extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final List<Vendor> vendors;
  final Function(Vendor)? onModify;
  final Function(Vendor)? onDelete;
  final Function(Vendor)? onVendorTap;
  final int slidableResetCounter;

  const VendorGroupSection({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.vendors,
    this.onModify,
    this.onDelete,
    this.onVendorTap,
    this.slidableResetCounter = 0,
  });

  @override
  State<VendorGroupSection> createState() => _VendorGroupSectionState();
}

class _VendorGroupSectionState extends State<VendorGroupSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.border;
    Color countBadgeColor = AppColors.textSecondary;
    Color countBadgeBg = AppColors.surfaceContainer;
    Color titleColor = AppColors.primary;

    if (widget.category == 'rental') {
      borderColor = AppColors.warning.withValues(alpha: 0.3);
      countBadgeColor = AppColors.warning;
      countBadgeBg = AppColors.warning.withValues(alpha: 0.1);
      titleColor = AppColors.warning;
    }

    const limit = 5;
    final showShowAll = !_isExpanded && widget.vendors.length > limit;
    final visibleVendors = showShowAll
        ? widget.vendors.take(limit).toList()
        : widget.vendors;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Color(0x0D0F172A),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.headlineSmall.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.description),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: Icon(Icons.info_outline, color: titleColor, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: countBadgeBg,
                  borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  '${widget.vendors.length}',
                  style: AppTypography.labelCaps.copyWith(
                    color: countBadgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.vendors.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  'No matching ${widget.title.toLowerCase()}s.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleVendors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final vendor = visibleVendors[index];
                return GestureDetector(
                  onTap: () => widget.onVendorTap?.call(vendor),
                  child: VendorCard(
                    key: ValueKey('${vendor.id}_${widget.slidableResetCounter}'),
                    vendor: vendor,
                    onModify: widget.onModify != null ? () => widget.onModify!(vendor) : null,
                    onDelete: widget.onDelete != null ? () => widget.onDelete!(vendor) : null,
                  ),
                );
              },
            ),
            if (showShowAll) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Text(
                    'Show all ${widget.vendors.length} →',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
