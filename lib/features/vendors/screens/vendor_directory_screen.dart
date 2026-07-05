import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/expandable_fab_menu.dart';
import '../../../shared/widgets/floating_search_fab.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/vendor_card.dart';
import '../modals/add_vendor_modal.dart';
import '../modals/edit_vendor_modal.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../widgets/vendor_action_menu.dart';
import '../providers/vendors_provider.dart';

/// Directory screen listing Retailer and Rental vendors.
class VendorDirectoryScreen extends ConsumerStatefulWidget {
  const VendorDirectoryScreen({super.key});

  @override
  ConsumerState<VendorDirectoryScreen> createState() =>
      _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends ConsumerState<VendorDirectoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAddModal = false;
  bool _showEditModal = false;
  bool _showDeleteModal = false;
  bool _showActionMenu = false;
  String? _modalInitialCategory;
  Vendor? _selectedVendorForAction;
  Vendor? _selectedVendorForEdit;
  Vendor? _selectedVendorForDelete;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _openAddVendorModal(String? category) {
    setState(() {
      _modalInitialCategory = category;
      _showAddModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorProvider);
    final vendors = vendorsAsync.valueOrNull ?? [];
    if (vendorsAsync.isLoading && vendors.isEmpty) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (vendorsAsync.hasError && vendors.isEmpty) {
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Text(
            'Error loading vendors: ${vendorsAsync.error}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final filteredVendors = vendors.where((vendor) {
      if (_searchQuery.isEmpty) return true;
      return vendor.name.toLowerCase().contains(_searchQuery) ||
          vendor.id.toLowerCase().contains(_searchQuery) ||
          vendor.location.toLowerCase().contains(_searchQuery);
    }).toList();

    final retailerVendors = filteredVendors
        .where((v) => v.category == 'retailer')
        .toList();
    final rentalVendors = filteredVendors
        .where((v) => v.category == 'rental')
        .toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.mobileGutter,
                AppDimensions.mobileGutter,
                AppDimensions.mobileGutter,
                100, // Margin to avoid overlap with FloatingSearchFAB
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header
                  const SectionHeader(
                    category: 'DIRECTORY',
                    title: 'Vendors',
                    description:
                        'Manage retail vendor records used in bookings and rental vendor records for halls and hotels.',
                  ),
                  const SizedBox(height: 24),

                  // Retailer Vendors Group Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.functionalRadius,
                      ),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: AppColors.shadowSoft,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Retailer Vendor',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (retailerVendors.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No matching retailer vendors.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: retailerVendors.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final vendor = retailerVendors[index];
                              return VendorCard(
                                vendor: vendor,
                                onMorePressed: () {
                                  setState(() {
                                    _selectedVendorForAction = vendor;
                                    _showActionMenu = true;
                                  });
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Rental Vendors Group Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.functionalRadius,
                      ),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: AppColors.shadowSoft,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Rental Vendors',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (rentalVendors.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No matching rental vendors.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rentalVendors.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final vendor = rentalVendors[index];
                              return VendorCard(
                                vendor: vendor,
                                onMorePressed: () {
                                  setState(() {
                                    _selectedVendorForAction = vendor;
                                    _showActionMenu = true;
                                  });
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pinned Search FAB at bottom containing ExpandableFABMenu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingSearchFAB(
                searchHint: 'Search vendors...',
                controller: _searchController,
                actionWidget: ExpandableFABMenu(
                  items: [
                    ExpandableFABItem(
                      icon: Icons.add_box,
                      label: 'NEW RETAILER',
                      onPressed: () => _openAddVendorModal('retailer'),
                    ),
                    ExpandableFABItem(
                      icon: Icons.store,
                      label: 'NEW RENTAL VENDOR',
                      onPressed: () => _openAddVendorModal('rental'),
                    ),
                  ],
                ),
              ),
            ),

            // Add Vendor Modal
            if (_showAddModal)
              AddVendorModal(
                initialCategory: _modalInitialCategory,
                onClose: () => setState(() => _showAddModal = false),
                onSave: (newVendor) {
                  ref.read(vendorProvider.notifier).addVendor(newVendor);
                  setState(() => _showAddModal = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vendor added successfully')),
                  );
                },
              ),

            // Edit Vendor Modal
            if (_showEditModal && _selectedVendorForEdit != null)
              EditVendorModal(
                vendor: _selectedVendorForEdit!,
                onClose: () => setState(() {
                  _showEditModal = false;
                  _selectedVendorForEdit = null;
                }),
                onSave: (updatedVendor) {
                  ref.read(vendorProvider.notifier).updateVendor(updatedVendor);
                  setState(() {
                    _showEditModal = false;
                    _selectedVendorForEdit = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vendor "${updatedVendor.name}" updated successfully',
                      ),
                    ),
                  );
                },
              ),

            // Delete Vendor Dialog
            if (_showDeleteModal && _selectedVendorForDelete != null)
              ConfirmationDialog(
                title: 'DELETE VENDOR',
                message:
                    'Are you sure you want to delete vendor "${_selectedVendorForDelete!.name}"? This action cannot be undone.',
                confirmText: 'DELETE',
                isDestructive: true,
                onCancel: () => setState(() {
                  _showDeleteModal = false;
                  _selectedVendorForDelete = null;
                }),
                onConfirm: () {
                  ref
                      .read(vendorProvider.notifier)
                      .deleteVendor(_selectedVendorForDelete!.id);
                  setState(() {
                    _showDeleteModal = false;
                    _selectedVendorForDelete = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vendor deleted successfully'),
                    ),
                  );
                },
              ),

            // Vendor Action Menu
            if (_showActionMenu && _selectedVendorForAction != null)
              VendorActionMenu(
                vendor: _selectedVendorForAction!,
                onClose: () => setState(() {
                  _showActionMenu = false;
                  _selectedVendorForAction = null;
                }),
                onEdit: () {
                  final v = _selectedVendorForAction!;
                  setState(() {
                    _selectedVendorForEdit = v;
                    _showEditModal = true;
                  });
                },
                onDelete: () {
                  final v = _selectedVendorForAction!;
                  setState(() {
                    _selectedVendorForDelete = v;
                    _showDeleteModal = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
