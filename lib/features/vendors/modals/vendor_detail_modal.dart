import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';

class VendorDetailModal extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final bool isVisible;

  const VendorDetailModal({
    super.key,
    required this.vendor,
    required this.onClose,
    required this.onEdit,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final displayLocation = (vendor.location.isEmpty || vendor.location == 'nan')
        ? 'N/A'
        : vendor.location;

    final formattedCategory = vendor.category == 'rental' ? 'Rental Vendor' : 'Retailer Vendor';

    return DraggableFormSheet(
      title: vendor.name,
      category: 'vendors',
      onClose: onClose,
      actions: [
        IconButton(
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
          tooltip: 'Edit Vendor',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoDetail('VENDOR ID', vendor.id),
                const SizedBox(height: 12),
                _buildInfoDetail('CATEGORY', formattedCategory),
                const SizedBox(height: 12),
                _buildInfoDetail('LOCATION', displayLocation),
                const SizedBox(height: 12),
                _buildPhoneDetail('PHONE NUMBER', vendor.phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneDetail(String label, String phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                phone,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.infoText,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.infoText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
