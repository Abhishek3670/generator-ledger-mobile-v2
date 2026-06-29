import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../shared/widgets/expandable_fab_menu.dart';
import '../../../shared/widgets/floating_search_fab.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/side_navigation_drawer.dart';
import '../widgets/inventory_group_section.dart';
import '../widgets/add_generator_modal.dart';
import '../widgets/edit_generator_modal.dart';
import '../widgets/generator_detail_modal.dart';
import '../widgets/generator_action_menu.dart';

/// Directory screen listing fleet generators grouped by inventory categories.
class GeneratorsDirectoryScreen extends StatefulWidget {
  const GeneratorsDirectoryScreen({super.key});

  @override
  State<GeneratorsDirectoryScreen> createState() => _GeneratorsDirectoryScreenState();
}

class _GeneratorsDirectoryScreenState extends State<GeneratorsDirectoryScreen> {
  final _searchController = TextEditingController();
  final _dateController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  late final FocusNode _dateFocusNode;
  bool _isDateFocused = false;

  late final List<MockGenerator> _generators;
  bool _showAddModal = false;
  bool _showEditModal = false;
  bool _showActionMenu = false;
  String? _modalInitialCategory;
  MockGenerator? _selectedGeneratorDetail;
  MockGenerator? _selectedGeneratorForAction;
  MockGenerator? _selectedGeneratorForEdit;

  @override
  void initState() {
    super.initState();
    _generators = List.from(mockGenerators);
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

  @override
  Widget build(BuildContext context) {
    // Filter mock generators based on search query
    final filteredGenerators = _generators.where((gen) {
      if (_searchQuery.isEmpty) return true;
      return gen.id.toLowerCase().contains(_searchQuery) ||
          gen.capacity.toLowerCase().contains(_searchQuery) ||
          gen.type.toLowerCase().contains(_searchQuery);
    }).toList();

    final retailerGensets = filteredGenerators.where((g) => g.category == 'retailer').toList();
    final permanentGensets = filteredGenerators.where((g) => g.category == 'permanent').toList();
    final emergencyGensets = filteredGenerators.where((g) => g.category == 'emergency').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'FLEET',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: SideNavigationDrawer(
        currentRoute: '/generators',
        onNavigate: (routePath) {
          context.go(routePath);
        },
        userName: 'Abhishek Sharma',
        userRole: 'Fleet Manager',
      ),
      floatingActionButton: ExpandableFABMenu(
        items: [
          ExpandableFABItem(
            icon: Icons.add_box,
            label: 'NEW RETAILER',
            onPressed: () => _openAddModal('retailer'),
          ),
          ExpandableFABItem(
            icon: Icons.emergency,
            label: 'EMERGENCY',
            onPressed: () => _openAddModal('emergency'),
          ),
        ],
      ),
      body: SafeArea(
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
                    title: 'Generators',
                    description: 'Track retailer, permanent, and emergency genset inventory, assignments, and availability.',
                  ),
                  const SizedBox(height: 20),

                  // Booked Date Card
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isDateFocused ? AppColors.primary : AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: TextFormField(
                                    focusNode: _dateFocusNode,
                                    controller: _dateController,
                                    readOnly: true,
                                    onTap: _selectDate,
                                    style: AppTypography.bodySmall,
                                    decoration: const InputDecoration(
                                      hintText: 'dd-mm-yyyy',
                                      suffixIcon: Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _dateController.clear();
                                    _selectedDate = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border, width: 1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'All',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Retailer Genset Group
                  InventoryGroupSection(
                    title: 'Retailer Genset',
                    description: 'Gensets used for normal bookings and day-to-day retailer assignments.',
                    category: 'retailer',
                    generators: retailerGensets,
                    onGeneratorTap: (gen) {
                      setState(() {
                        _selectedGeneratorDetail = gen;
                      });
                    },
                    onModify: (gen) {
                      setState(() {
                        _selectedGeneratorForAction = gen;
                        _showActionMenu = true;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Permanent Genset Group
                  InventoryGroupSection(
                    title: 'Permanent Genset',
                    description: 'Gensets permanently parked at Rental Vendor properties such as marriage halls.',
                    category: 'permanent',
                    generators: permanentGensets,
                    onGeneratorTap: (gen) {
                      setState(() {
                        _selectedGeneratorDetail = gen;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Emergency Genset Group
                  InventoryGroupSection(
                    title: 'Emergency Genset',
                    description: 'Backup gensets kept ready when any genset fails or emergency coverage is requested.',
                    category: 'emergency',
                    generators: emergencyGensets,
                    onGeneratorTap: (gen) {
                      setState(() {
                        _selectedGeneratorDetail = gen;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Pinned search bar at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FloatingSearchFAB(
                searchHint: 'Search generators...',
                controller: _searchController,
                fabIcon: Icons.add,
                onFABPressed: () => _openAddModal(null),
              ),
            ),

            // Add Generator Modal
            if (_showAddModal)
              AddGeneratorModal(
                initialCategory: _modalInitialCategory,
                onClose: () => setState(() => _showAddModal = false),
                onSave: (newGen) {
                  setState(() {
                    _generators.insert(0, newGen);
                    _showAddModal = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generator added successfully')),
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
                  setState(() {
                    final index = _generators.indexWhere((g) => g.id == _selectedGeneratorForEdit!.id);
                    if (index != -1) {
                      _generators[index] = updatedGen;
                    }
                    _showEditModal = false;
                    _selectedGeneratorForEdit = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generator "${updatedGen.id}" updated successfully')),
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
                    _generators.removeWhere((g) => g.id == gen.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generator deleted successfully')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
