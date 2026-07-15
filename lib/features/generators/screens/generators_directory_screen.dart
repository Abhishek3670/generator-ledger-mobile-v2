import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/expandable_fab_menu.dart';
import '../../../shared/widgets/floating_search_fab.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../widgets/inventory_group_section.dart';
import '../modals/add_generator_modal.dart';
import '../modals/edit_generator_modal.dart';
import '../modals/generator_detail_modal.dart';
import '../widgets/generator_action_menu.dart';
import '../providers/generators_provider.dart';
import '../../../shared/widgets/destructive_confirmation_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/routing/app_router.dart';

/// Directory screen listing fleet generators grouped by inventory categories.
class GeneratorsDirectoryScreen extends ConsumerStatefulWidget {
  const GeneratorsDirectoryScreen({super.key});

  @override
  ConsumerState<GeneratorsDirectoryScreen> createState() =>
      _GeneratorsDirectoryScreenState();
}

class _GeneratorsDirectoryScreenState
    extends ConsumerState<GeneratorsDirectoryScreen> with RouteAware {
  final _searchController = TextEditingController();
  final _dateController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _bookingStatusFilter = 'All'; // 'All', 'Booked', 'Free'
  String _capacitySort = 'default'; // 'default', 'asc', 'desc'

  int _parseCapacity(String cap) {
    final numericPart = cap.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numericPart) ?? 0;
  }

  void _showFilterAndSortSheet() {
    String tempBookingStatus = _bookingStatusFilter;
    String tempCapacitySort = _capacitySort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters & Sort',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Booking Status Segment
                    Text(
                      'BOOKING STATUS',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSheetChip(
                          label: 'All',
                          isSelected: tempBookingStatus == 'All',
                          isDisabled: _selectedDate == null,
                          onTap: () {
                            setSheetState(() {
                              tempBookingStatus = 'All';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSheetChip(
                          label: 'Booked',
                          isSelected: tempBookingStatus == 'Booked',
                          isDisabled: _selectedDate == null,
                          onTap: () {
                            setSheetState(() {
                              tempBookingStatus = 'Booked';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSheetChip(
                          label: 'Free',
                          isSelected: tempBookingStatus == 'Free',
                          isDisabled: _selectedDate == null,
                          onTap: () {
                            setSheetState(() {
                              tempBookingStatus = 'Free';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sort By Segment
                    Text(
                      'SORT BY',
                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSheetChip(
                          label: 'Default',
                          isSelected: tempCapacitySort == 'default',
                          onTap: () {
                            setSheetState(() {
                              tempCapacitySort = 'default';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSheetChip(
                          label: 'Cap L-H',
                          isSelected: tempCapacitySort == 'asc',
                          onTap: () {
                            setSheetState(() {
                              tempCapacitySort = 'asc';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildSheetChip(
                          label: 'Cap H-L',
                          isSelected: tempCapacitySort == 'desc',
                          onTap: () {
                            setSheetState(() {
                              tempCapacitySort = 'desc';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _bookingStatusFilter = tempBookingStatus;
                          _capacitySort = tempCapacitySort;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'APPLY',
                        style: AppTypography.labelCaps.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final bgColor = isSelected ? AppColors.primary : Colors.white;
    final textColor = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (isSelected ? Colors.white : AppColors.textSecondary);
    final borderColor = isDisabled
        ? AppColors.border.withValues(alpha: 0.5)
        : AppColors.border;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(9999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _showAddModal = false;
  bool _showEditModal = false;
  bool _showDeleteModal = false;
  bool _showActionMenu = false;
  String? _modalInitialCategory;
  MockGenerator? _selectedGeneratorDetail;
  MockGenerator? _selectedGeneratorForAction;
  MockGenerator? _selectedGeneratorForEdit;
  MockGenerator? _selectedGeneratorForDelete;

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
    _dateController.dispose();
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
      ref.read(generatorProvider.notifier).loadGenerators(
        date: DateFormat('yyyy-MM-dd').format(picked),
      );
    }
  }

  void _openAddModal(String? category) {
    setState(() {
      _modalInitialCategory = category;
      _showAddModal = true;
    });
  }

  Widget _buildGeneratorContent(
    List<MockGenerator> retailerGensets,
    List<MockGenerator> permanentGensets,
    List<MockGenerator> emergencyGensets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Retailer Genset Group
        InventoryGroupSection(
          title: 'Retailer Genset',
          description:
              'Gensets rented out to retail vendors for events like marriages.',
          category: 'retailer',
          generators: retailerGensets,
          slidableResetCounter: _slidableResetCounter,
          onGeneratorTap: (gen) {
            setState(() {
              _selectedGeneratorDetail = gen;
            });
          },
          onModify: (gen) {
            setState(() {
              _selectedGeneratorForEdit = gen;
              _showEditModal = true;
            });
          },
          onDelete: (gen) {
            setState(() {
              _selectedGeneratorForDelete = gen;
              _showDeleteModal = true;
            });
          },
        ),
        const SizedBox(height: 20),

        // Permanent Genset Group
        InventoryGroupSection(
          title: 'Permanent Genset',
          description:
              'Gensets permanently parked at Rental Vendor properties such as marriage halls.',
          category: 'permanent',
          generators: permanentGensets,
          slidableResetCounter: _slidableResetCounter,
          onGeneratorTap: (gen) {
            setState(() {
              _selectedGeneratorDetail = gen;
            });
          },
          onModify: (gen) {
            setState(() {
              _selectedGeneratorForEdit = gen;
              _showEditModal = true;
            });
          },
          onDelete: (gen) {
            setState(() {
              _selectedGeneratorForDelete = gen;
              _showDeleteModal = true;
            });
          },
        ),
        const SizedBox(height: 20),

        // Emergency Genset Group
        InventoryGroupSection(
          title: 'Emergency Genset',
          description:
              'Backup gensets kept ready when any genset fails or emergency coverage is requested.',
          category: 'emergency',
          generators: emergencyGensets,
          slidableResetCounter: _slidableResetCounter,
          onGeneratorTap: (gen) {
            setState(() {
              _selectedGeneratorDetail = gen;
            });
          },
          onModify: (gen) {
            setState(() {
              _selectedGeneratorForEdit = gen;
              _showEditModal = true;
            });
          },
          onDelete: (gen) {
            setState(() {
              _selectedGeneratorForDelete = gen;
              _showDeleteModal = true;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final generatorsAsync = ref.watch(generatorProvider);
    final connectivity = ref.watch(connectivityProvider);
    final generators = generatorsAsync.valueOrNull ?? [];

    // Detect tab changes to close swipe actions
    try {
      final shell = StatefulNavigationShell.of(context);
      final currentIndex = shell.currentIndex;
      if (_lastIndex != null && _lastIndex != currentIndex) {
        _closeAllSwipeRows();
      }
      _lastIndex = currentIndex;
    } catch (_) {}

    var filteredGenerators = generators.where((gen) {
      if (_searchQuery.isEmpty) return true;
      return gen.id.toLowerCase().contains(_searchQuery) ||
          gen.capacity.toLowerCase().contains(_searchQuery) ||
          gen.type.toLowerCase().contains(_searchQuery);
    }).toList();

    if (_selectedDate != null && _bookingStatusFilter != 'All') {
      final filterLower = _bookingStatusFilter.toLowerCase();
      filteredGenerators = filteredGenerators.where((gen) {
        return gen.bookingStatus?.toLowerCase() == filterLower;
      }).toList();
    }

    if (_capacitySort != 'default') {
      filteredGenerators.sort((a, b) {
        final capA = _parseCapacity(a.capacity);
        final capB = _parseCapacity(b.capacity);
        if (_capacitySort == 'asc') {
          return capA.compareTo(capB);
        } else {
          return capB.compareTo(capA);
        }
      });
    }

    final retailerGensets = filteredGenerators
        .where((g) => g.category == 'retailer')
        .toList();
    final permanentGensets = filteredGenerators
        .where((g) => g.category == 'permanent')
        .toList();
    final emergencyGensets = filteredGenerators
        .where((g) => g.category == 'emergency')
        .toList();

    return Container(
      color: AppColors.background,
      child: SlidableAutoCloseBehavior(
        child: SafeArea(
          child: Stack(
            children: [
            RefreshIndicator(
              onRefresh: () async {
                await ref.read(generatorProvider.notifier).loadGenerators();
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
                      title: 'Generators',
                    ),
                    const SizedBox(height: 12),

                    // Filter and Sort Bar
                    // Filter and Sort Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date Filter Pill
                        Container(
                          decoration: BoxDecoration(
                            color: _selectedDate != null ? AppColors.primary : Colors.white,
                            border: Border.all(
                              color: _selectedDate != null ? AppColors.primary : AppColors.border,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _selectDate,
                                borderRadius: _selectedDate != null
                                    ? const BorderRadius.horizontal(left: Radius.circular(9999))
                                    : BorderRadius.circular(9999),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(12, 6, _selectedDate != null ? 8 : 12, 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: _selectedDate != null ? Colors.white : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedDate != null
                                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                            : 'All Dates',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: _selectedDate != null ? Colors.white : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_selectedDate == null) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          size: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedDate != null) ...[
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = null;
                                      _dateController.clear();
                                      _bookingStatusFilter = 'All';
                                    });
                                    ref.read(generatorProvider.notifier).loadGenerators();
                                  },
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(9999)),
                                  child: const Padding(
                                    padding: EdgeInsets.fromLTRB(4, 6, 12, 6),
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Filter Icon Button
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: _showFilterAndSortSheet,
                              icon: const Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
                              style: IconButton.styleFrom(
                                side: const BorderSide(color: AppColors.border, width: 1),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            if (_bookingStatusFilter != 'All' || _capacitySort != 'default')
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent, // amber CTA dot
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    generatorsAsync.when(
                      data: (_) => _buildGeneratorContent(
                        retailerGensets,
                        permanentGensets,
                        emergencyGensets,
                      ),
                      loading: () => Column(
                        children: List.generate(3, (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: SkeletonCard(height: 120),
                        )),
                      ),
                      error: (error, stack) => ErrorScreen(
                        message: error.toString(),
                        onRetry: () => ref.read(generatorProvider.notifier).loadGenerators(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pinned search bar at bottom containing ExpandableFABMenu
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingSearchFAB(
                searchHint: 'Search generators...',
                controller: _searchController,
                actionWidget: ExpandableFABMenu(
                  items: [
                    ExpandableFABItem(
                      icon: Icons.storefront,
                      label: 'NEW RETAILER',
                      onPressed: () => _openAddModal('retailer'),
                    ),
                    ExpandableFABItem(
                      icon: Icons.domain,
                      label: 'NEW PERMANENT',
                      onPressed: () => _openAddModal('permanent'),
                    ),
                    ExpandableFABItem(
                      icon: Icons.emergency,
                      label: 'EMERGENCY',
                      onPressed: () => _openAddModal('emergency'),
                    ),
                  ],
                ),
              ),
            ),

            // Add Generator Modal
            if (_showAddModal)
              AddGeneratorModal(
                initialCategory: _modalInitialCategory,
                onClose: () => setState(() => _showAddModal = false),
                onSave: (newGen) {
                  ref.read(generatorProvider.notifier).addGenerator(newGen);
                  setState(() => _showAddModal = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generator added successfully'),
                    ),
                  );
                },
              ),

            // Edit Generator Modal
            if (_showEditModal && _selectedGeneratorForEdit != null)
              EditGeneratorModal(
                generator: _selectedGeneratorForEdit!,
                onClose: () => setState(() {
                  _showEditModal = false;
                  _selectedGeneratorForEdit = null;
                }),
                onSave: (updatedGen) {
                  ref
                      .read(generatorProvider.notifier)
                      .updateGenerator(updatedGen);
                  setState(() {
                    _showEditModal = false;
                    _selectedGeneratorForEdit = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Generator "${updatedGen.id}" updated successfully',
                      ),
                    ),
                  );
                },
              ),

            // Generator Detail Modal
            if (_selectedGeneratorDetail != null)
              GeneratorDetailModal(
                generator: _selectedGeneratorDetail!,
                onClose: () => setState(() => _selectedGeneratorDetail = null),
                onEdit: () {
                  final gen = _selectedGeneratorDetail!;
                  setState(() {
                    _selectedGeneratorDetail = null;
                    _selectedGeneratorForEdit = gen;
                    _showEditModal = true;
                  });
                },
              ),

            // Generator Action Menu
            if (_showActionMenu && _selectedGeneratorForAction != null)
              GeneratorActionMenu(
                generator: _selectedGeneratorForAction!,
                onClose: () => setState(() {
                  _showActionMenu = false;
                  _selectedGeneratorForAction = null;
                }),
                onEdit: () {
                  final gen = _selectedGeneratorForAction!;
                  setState(() {
                    _selectedGeneratorForEdit = gen;
                    _showEditModal = true;
                  });
                },
                onDelete: () {
                  final gen = _selectedGeneratorForAction!;
                  setState(() {
                    _showActionMenu = false;
                    _selectedGeneratorForAction = null;
                    _selectedGeneratorForDelete = gen;
                    _showDeleteModal = true;
                  });
                },
              ),

            // Delete Generator Dialog
            if (_showDeleteModal && _selectedGeneratorForDelete != null)
              DestructiveConfirmationDialog(
                title: 'DELETE GENERATOR',
                message:
                    'Are you sure you want to delete generator "${_selectedGeneratorForDelete!.id}"? This will remove the generator and its booking history.',
                onCancel: () => setState(() {
                  _showDeleteModal = false;
                  _selectedGeneratorForDelete = null;
                }),
                onConfirm: () {
                  final generatorId = _selectedGeneratorForDelete!.id;
                  ref
                      .read(generatorProvider.notifier)
                      .deleteGenerator(_selectedGeneratorForDelete!.id);
                  setState(() {
                    _showDeleteModal = false;
                    _selectedGeneratorForDelete = null;
                  });
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Generator "$generatorId" deleted'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          ref.read(generatorProvider.notifier).undoDeleteGenerator();
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
