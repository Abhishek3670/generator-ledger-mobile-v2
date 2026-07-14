import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/widgets/draggable_form_sheet.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/services/user_preferences_service.dart';
import '../modals/add_booking_modal.dart';

class EditBookingModal extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback onClose;
  final Function(Booking)? onSave;
  final bool isVisible;

  const EditBookingModal({
    super.key,
    required this.booking,
    required this.onClose,
    this.onSave,
    this.isVisible = true,
  });

  @override
  ConsumerState<EditBookingModal> createState() => _EditBookingModalState();
}

class _EditBookingModalState extends ConsumerState<EditBookingModal> {
  String _searchQuery = '';
  bool _showAddBookingModal = false;

  void _openAddBookingModal() async {
    await ref.read(userPreferencesServiceProvider).saveLastVendor(widget.booking.vendorId);
    setState(() {
      _showAddBookingModal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(bookingProvider);

    return Stack(
      children: [
        DraggableFormSheet(
          title: widget.booking.vendorName,
          category: 'EDIT BOOKING',
          onClose: widget.onClose,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primary,
                shape: const CircleBorder(),
                onPressed: _openAddBookingModal,
                child: const Icon(Icons.add),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Booking Date Header
              Text(
                DateFormat('MMMM dd, yyyy').format(widget.booking.date),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Section Title
              Text(
                'Edit Assigned Generators',
                style: AppTypography.title.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Search Input
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search assigned assets...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Cards List
              bookingsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text('Error loading assets: $err'),
                  ),
                ),
                data: (bookings) {
                  final vendorBookings = bookings
                      .where((b) => b.vendorId == widget.booking.vendorId)
                      .toList();
                  final filteredBookings = vendorBookings.where((b) {
                    if (_searchQuery.isEmpty) return true;
                    return b.generatorId.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredBookings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No assigned assets found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: filteredBookings.map((booking) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _GeneratorAssignmentCard(
                          key: ValueKey(booking.id),
                          booking: booking,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        if (_showAddBookingModal)
          AddBookingModal(
            onClose: () {
              setState(() {
                _showAddBookingModal = false;
              });
            },
            onSave: (newBookings) async {
              setState(() {
                _showAddBookingModal = false;
              });
              for (final b in newBookings) {
                await ref.read(bookingProvider.notifier).addBooking(b);
              }
            },
            isVisible: true,
          ),
      ],
    );
  }
}

class _GeneratorAssignmentCard extends ConsumerStatefulWidget {
  final Booking booking;

  const _GeneratorAssignmentCard({
    super.key,
    required this.booking,
  });

  @override
  ConsumerState<_GeneratorAssignmentCard> createState() =>
      __GeneratorAssignmentCardState();
}

class __GeneratorAssignmentCardState extends ConsumerState<_GeneratorAssignmentCard> {
  late final TextEditingController _remarksController;
  late final FocusNode _remarksFocusNode;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.booking.notes);
    _remarksFocusNode = FocusNode();
    _remarksFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _remarksFocusNode.removeListener(_onFocusChange);
    _remarksFocusNode.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_remarksFocusNode.hasFocus) {
      final currentNotes = _remarksController.text.trim();
      if (currentNotes != widget.booking.notes) {
        ref.read(bookingProvider.notifier).updateBooking(
              widget.booking.copyWith(notes: currentNotes),
            );
      }
    }
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelCaps.copyWith(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.booking.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => ConfirmationDialog(
            title: 'Delete Assignment',
            message: 'Are you sure you want to remove this generator assignment?',
            confirmText: 'DELETE',
            cancelText: 'CANCEL',
            isDestructive: true,
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (direction) {
        ref.read(bookingProvider.notifier).deleteBooking(widget.booking.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generator ID + Capacity badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.booking.generatorId,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    widget.booking.capacity,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Deployment Date field
            _buildFieldLabel('DEPLOYMENT DATE'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy-MM-dd').format(widget.booking.date),
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Remarks field
            _buildFieldLabel('REMARKS'),
            const SizedBox(height: 6),
            TextFormField(
              focusNode: _remarksFocusNode,
              controller: _remarksController,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Add remarks...',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
