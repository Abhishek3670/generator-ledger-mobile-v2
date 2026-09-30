import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/mock/mock_bookings.dart';
import '../../../data/mock/mock_vendors.dart';
import '../../../data/mock/mock_generators.dart';
import '../../../core/navigation/hero_tags.dart';
import '../modals/edit_generator_modal.dart';
import '../widgets/generator_action_menu.dart';

class GeneratorDetailScreen extends StatefulWidget {
  final String generatorId;

  const GeneratorDetailScreen({
    super.key,
    required this.generatorId,
  });

  @override
  State<GeneratorDetailScreen> createState() => _GeneratorDetailScreenState();
}

class _GeneratorDetailScreenState extends State<GeneratorDetailScreen> {
  String? _selectedVendorId;
  DateTime? _selectedDate;
  final TextEditingController _remarksController = TextEditingController();

  late List<MockBooking> _generatorBookings;
  late MockGenerator _generator;
  bool _showActionMenu = false;
  bool _showEditModal = false;

  @override
  void initState() {
    super.initState();
    _loadGeneratorDetails();
  }

  void _loadGeneratorDetails() {
    // Find the generator from mockGenerators or construct a default one if not found
    final existingGen = mockGenerators.where((g) => g.id == widget.generatorId);
    if (existingGen.isNotEmpty) {
      _generator = existingGen.first;
    } else {
      // Default fallback
      _generator = MockGenerator(
        id: widget.generatorId,
        capacity: '100 kVA',
        type: '6R',
        status: 'active',
        category: 'retailer',
      );
    }

    _refreshBookings();
  }

  void _refreshBookings() {
    setState(() {
      _generatorBookings = mockBookings.where((booking) => booking.generatorId == widget.generatorId).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // newest first
    });
  }

  void _handleCreateBooking() {
    if (_selectedVendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    final vendor = mockVendors.firstWhere((v) => v.id == _selectedVendorId);

    final newBookingId = 'BK-${mockBookings.length + 100}';
    final newBooking = MockBooking(
      id: newBookingId,
      vendorId: vendor.id,
      vendorName: vendor.name,
      generatorId: _generator.id,
      capacity: _generator.capacity,
      date: _selectedDate!,
      status: 'confirmed',
    );

    // Add to mockBookings in memory
    mockBookings.add(newBooking);

    // Reset form fields
    setState(() {
      _selectedVendorId = null;
      _selectedDate = null;
      _remarksController.clear();
    });

    _refreshBookings();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking created successfully')),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'GENERATOR DETAILS',
          style: AppTypography.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              setState(() {
                _showActionMenu = true;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Identity Section
              Hero(
                tag: HeroTags.generatorCard(_generator.id),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _generator.id,
                              style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    '${_generator.category.toUpperCase()} GENSET',
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    _generator.capacity.toUpperCase(),
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                ),
                                if (_generator.type.isNotEmpty && _generator.type != '-')
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      _generator.type.toUpperCase(),
                                      style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Availability Status Badge
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Available',
                              style: AppTypography.labelCaps.copyWith(color: AppColors.success, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Booking Form Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_available, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Create Booking',
                                style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a booked date to reserve this generator.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Vendor Dropdown
                          Text(
                            'VENDOR *',
                            style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedVendorId,
                                hint: Text('Select a vendor', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                dropdownColor: Colors.white,
                                items: mockVendors.map((vendor) {
                                  return DropdownMenuItem<String>(
                                    value: vendor.id,
                                    child: Text('${vendor.name} (${vendor.id})', style: AppTypography.bodyMedium),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVendorId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Booked Date Picker Input
                          Text(
                            'BOOKED DATE *',
                            style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate == null
                                        ? 'Select date'
                                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _selectedDate == null ? AppColors.textSecondary : AppColors.primary,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Remarks Input
                          Text(
                            'REMARKS (OPTIONAL)',
                            style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _remarksController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add any specific requirements...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              fillColor: AppColors.surface,
                              filled: true,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: 20),

                          // Submit Action Button
                          ElevatedButton(
                            onPressed: _handleCreateBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Booking',
                                  style: AppTypography.headlineSmall.copyWith(color: AppColors.primary, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Bookings List
              Text(
                'RECENT BOOKINGS',
                style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              if (_generatorBookings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No bookings found for this generator.')),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _generatorBookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final booking = _generatorBookings[index];
                    final isConfirmed = booking.status == 'confirmed';
                    final isCancelled = booking.status == 'cancelled';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                booking.id,
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? const Color(0xFFECFDF5)
                                      : isCancelled
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFFFFBEB),
                                  border: Border.all(
                                    color: isConfirmed
                                        ? AppColors.success.withValues(alpha: 0.2)
                                        : isCancelled
                                            ? AppColors.danger.withValues(alpha: 0.2)
                                            : AppColors.warning.withValues(alpha: 0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isConfirmed
                                          ? Icons.check
                                          : isCancelled
                                              ? Icons.close
                                              : Icons.access_time,
                                      size: 12,
                                      color: isConfirmed
                                          ? AppColors.success
                                          : isCancelled
                                              ? AppColors.danger
                                              : AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      booking.status.toUpperCase(),
                                      style: TextStyle(
                                        color: isConfirmed
                                            ? AppColors.success
                                            : isCancelled
                                                ? AppColors.danger
                                                : AppColors.warning,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VENDOR',
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.vendorName,
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'DATE',
                                    style: AppTypography.labelCaps.copyWith(color: AppColors.textSecondary, fontSize: 9),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(booking.date),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isCancelled ? AppColors.textSecondary : AppColors.primary,
                                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/bookings'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'View All Bookings',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),

          if (_showActionMenu)
            GeneratorActionMenu(
              generator: _generator,
              onClose: () => setState(() => _showActionMenu = false),
              onEdit: () {
                setState(() {
                  _showActionMenu = false;
                  _showEditModal = true;
                });
              },
              onDelete: () {
                mockGenerators.removeWhere((g) => g.id == _generator.id);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generator deleted successfully')),
                );
              },
            ),

          if (_showEditModal)
            EditGeneratorModal(
              generator: _generator,
              onClose: () => setState(() => _showEditModal = false),
              onSave: (updatedGen) {
                setState(() {
                  _generator = updatedGen;
                  final idx = mockGenerators.indexWhere((g) => g.id == widget.generatorId);
                  if (idx != -1) {
                    mockGenerators[idx] = updatedGen;
                  }
                  _showEditModal = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generator details updated successfully')),
                );
              },
            ),
        ],
      ),
    );
  }
}
