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

/// Directory screen listing fleet generators grouped by inventory categories.
class GeneratorsDirectoryScreen extends ConsumerStatefulWidget {
  const GeneratorsDirectoryScreen({super.key});

  @override
  ConsumerState<GeneratorsDirectoryScreen> createState() =>
      _GeneratorsDirectoryScreenState();
}

class _GeneratorsDirectoryScreenState
    extends ConsumerState<GeneratorsDirectoryScreen> {
  final _searchController = TextEditingController();
  final _dateController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  late final FocusNode _dateFocusNode;
  bool _isDateFocused = false;

  bool _showAddModal = false;
  bool _showEditModal = false;
  bool _showDeleteModal = false;
  bool _showActionMenu = false;
  String? _modalInitialCategory;
  MockGenerator? _selectedGeneratorDetail;
  MockGenerator? _selectedGeneratorForAction;
  MockGenerator? _selectedGeneratorForEdit;
  MockGenerator? _selectedGeneratorForDelete;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _dateFocusNode = FocusNode();
    _dateFocusNode.addListener(_onDateFocusChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _dateController.dispose();
    _dateFocusNode.removeListener(_onDateFocusChange);
    _dateFocusNode.dispose();
    super.dispose();
  }

  void _onDateFocusChange() {
    setState(() {
      _isDateFocused = _dateFocusNode.hasFocus;
    });
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
          onGeneratorTap: (gen) {
            context.push('/generators/${gen.id}');
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
          onGeneratorTap: (gen) {
            context.push('/generators/${gen.id}');
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
          onGeneratorTap: (gen) {
            context.push('/generators/${gen.id}');
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

    final filteredGenerators = generators.where((gen) {
      if (_searchQuery.isEmpty) return true;
      return gen.id.toLowerCase().contains(_searchQuery) ||
          gen.capacity.toLowerCase().contains(_searchQuery) ||
          gen.type.toLowerCase().contains(_searchQuery);
    }).toList();

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
                      description:
                          'Track retailer, permanent, and emergency genset inventory, assignments, and availability.',
                    ),
                    const SizedBox(height: 20),

                    // Booked Date Card
                    Container(
                      padding: const EdgeInsets.all(16.0),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BOOKED DATE',
                            style: AppTypography.labelCaps.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _isDateFocused
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.functionalRadius,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDate != null
                                              ? DateFormat(
                                                  'dd MMMM yyyy',
                                                ).format(_selectedDate!)
                                              : 'All',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                color: _selectedDate != null
                                                    ? AppColors.primary
                                                    : AppColors.textSecondary,
                                              ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedDate != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                      _dateController.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 16),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.border.withValues(
                                      alpha: 0.3,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
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
                  ref
                      .read(generatorProvider.notifier)
                      .deleteGenerator(_selectedGeneratorForDelete!.id);
                  setState(() {
                    _showDeleteModal = false;
                    _selectedGeneratorForDelete = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generator deleted successfully'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
