import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../shared/models/vendor.dart';
import '../../../shared/widgets/expandable_fab_menu.dart';
import '../../../shared/widgets/floating_search_fab.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../widgets/vendor_group_section.dart';
import '../modals/add_vendor_modal.dart';
import '../modals/edit_vendor_modal.dart';
import '../modals/vendor_detail_modal.dart';
import '../../../shared/widgets/destructive_confirmation_dialog.dart';
import '../providers/vendors_provider.dart';

/// Directory screen listing Retailer and Rental vendors.
class VendorDirectoryScreen extends ConsumerStatefulWidget {
  const VendorDirectoryScreen({super.key});

  @override
  ConsumerState<VendorDirectoryScreen> createState() =>
      _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends ConsumerState<VendorDirectoryScreen>
    with RouteAware {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAddModal = false;
  bool _showEditModal = false;
  bool _showDeleteModal = false;
  String? _modalInitialCategory;
  Vendor? _selectedVendorDetail;
  Vendor? _selectedVendorForEdit;
  Vendor? _selectedVendorForDelete;

  int _slidableResetCounter = 0;
  int? _lastIndex;

  void _closeAllSwipeRows() {
    if (mounted) {
      setState(() {
        _slidableResetCounter++;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRouter.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _closeAllSwipeRows();
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

  Widget _buildVendorLists(List<Vendor> vendors) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Retailer Vendors Group Section
        VendorGroupSection(
          title: 'Retailer Vendor',
          description: 'Manage retail vendor records used in bookings.',
          category: 'retailer',
          vendors: retailerVendors,
          slidableResetCounter: _slidableResetCounter,
          onVendorTap: (vendor) {
            setState(() {
              _selectedVendorDetail = vendor;
            });
          },
          onModify: (vendor) {
            setState(() {
              _selectedVendorForEdit = vendor;
              _showEditModal = true;
            });
          },
          onDelete: (vendor) {
            setState(() {
              _selectedVendorForDelete = vendor;
              _showDeleteModal = true;
            });
          },
        ),
        const SizedBox(height: 24),

        // Rental Vendors Group Section
        VendorGroupSection(
          title: 'Rental Vendor',
          description: 'Manage rental vendor records for halls and hotels.',
          category: 'rental',
          vendors: rentalVendors,
          slidableResetCounter: _slidableResetCounter,
          onVendorTap: (vendor) {
            setState(() {
              _selectedVendorDetail = vendor;
            });
          },
          onModify: (vendor) {
            setState(() {
              _selectedVendorForEdit = vendor;
              _showEditModal = true;
            });
          },
          onDelete: (vendor) {
            setState(() {
              _selectedVendorForDelete = vendor;
              _showDeleteModal = true;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorProvider);
    final connectivity = ref.watch(connectivityProvider);

    // Detect tab changes to close swipe actions
    try {
      final shell = StatefulNavigationShell.of(context);
      final currentIndex = shell.currentIndex;
      if (_lastIndex != null && _lastIndex != currentIndex) {
        _closeAllSwipeRows();
      }
      _lastIndex = currentIndex;
    } catch (_) {}

    return Container(
      color: AppColors.background,
      child: SlidableAutoCloseBehavior(
        child: SafeArea(
          child: Stack(
            children: [
            RefreshIndicator(
              onRefresh: () async {
                await ref.read(vendorProvider.notifier).loadVendors();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.mobileGutter,
                  AppDimensions.mobileGutter,
                  AppDimensions.mobileGutter,
                  100, // Margin to avoid overlap with FloatingSearchFAB
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connectivity.value == ConnectivityResult.none) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off, color: AppColors.warningText, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Offline Mode - Viewing Cached Data',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warningText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Page Header
                    const SectionHeader(
                      category: 'DIRECTORY',
                      title: 'Vendors',
                    ),
                    const SizedBox(height: 24),

                    vendorsAsync.when(
                      data: (vendors) => _buildVendorLists(vendors),
                      loading: () => Column(
                        children: List.generate(3, (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: SkeletonCard(height: 100),
                        )),
                      ),
                      error: (error, stack) => ErrorScreen(
                        message: error.toString(),
                        onRetry: () => ref.read(vendorProvider.notifier).loadVendors(),
                      ),
                    ),
                  ],
                ),
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

            // Vendor Detail Modal
            if (_selectedVendorDetail != null)
              VendorDetailModal(
                vendor: _selectedVendorDetail!,
                onClose: () => setState(() => _selectedVendorDetail = null),
                onEdit: () {
                  final vendor = _selectedVendorDetail!;
                  setState(() {
                    _selectedVendorDetail = null;
                    _selectedVendorForEdit = vendor;
                    _showEditModal = true;
                  });
                },
              ),

            // Delete Vendor Dialog
            if (_showDeleteModal && _selectedVendorForDelete != null)
              DestructiveConfirmationDialog(
                title: 'DELETE VENDOR',
                message:
                    'Are you sure you want to delete vendor "${_selectedVendorForDelete!.name}"? This will remove the vendor and their booking history.',
                onCancel: () => setState(() {
                  _showDeleteModal = false;
                  _selectedVendorForDelete = null;
                }),
                onConfirm: () {
                  final vendorName = _selectedVendorForDelete!.name;
                  ref
                      .read(vendorProvider.notifier)
                      .deleteVendor(_selectedVendorForDelete!.id);
                  setState(() {
                    _showDeleteModal = false;
                    _selectedVendorForDelete = null;
                  });
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vendor "$vendorName" deleted'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          ref.read(vendorProvider.notifier).undoDeleteVendor();
                        },
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      ),
    );
  }
}
