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

                  // Flatten into individual BookingItem entries
                  final allItems = <({BookingItem item, Booking parentBooking})>[];
                  for (final booking in vendorBookings) {
                    if (booking.items.isNotEmpty) {
                      for (final item in booking.items) {
                        allItems.add((item: item, parentBooking: booking));
                      }
                    } else {
                      // Fallback: synthesize from booking's generators list
                      for (final genId in booking.generators) {
                        final capacityNum = int.tryParse(booking.capacity.replaceAll(RegExp(r'[^0-9]'), ''));
                        allItems.add((
                          item: BookingItem(
                            generatorId: genId,
                            capacityKva: capacityNum,
                            startDt: booking.formatBookingDate(),
                            itemStatus: booking.status,
                            isEmergency: false,
                            remarks: booking.notes,
                          ),
                          parentBooking: booking,
                        ));
                      }
                    }
                  }

                  // Apply search query filter on item.generatorId
                  final filteredItems = allItems.where((entry) {
                    if (_searchQuery.isEmpty) return true;
                    return entry.item.generatorId.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredItems.isEmpty) {
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
                    children: [
                      ...filteredItems.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _GeneratorAssignmentCard(
                            key: ValueKey('${entry.parentBooking.id}_${entry.item.generatorId}_${entry.item.startDt}'),
                            item: entry.item,
                            parentBooking: entry.parentBooking,
                          ),
                        );
                      }),
                      const SizedBox(height: 72),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primary,
            shape: const CircleBorder(),
            onPressed: _openAddBookingModal,
            child: const Icon(Icons.add),
          ),
        ),
        if (_showAddBookingModal)
          AddBookingModal(
            lockedVendorId: widget.booking.vendorId,
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
  final BookingItem item;
  final Booking parentBooking;

  const _GeneratorAssignmentCard({
    super.key,
    required this.item,
    required this.parentBooking,
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
    _remarksController = TextEditingController(text: widget.item.remarks);
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
      final currentRemarks = _remarksController.text.trim();
      if (currentRemarks != widget.item.remarks) {
        List<BookingItem> updatedItems = [];
        if (widget.parentBooking.items.isNotEmpty) {
          updatedItems = widget.parentBooking.items.map((i) {
            if (i.generatorId == widget.item.generatorId && i.startDt == widget.item.startDt) {
              return BookingItem(
                generatorId: i.generatorId,
                capacityKva: i.capacityKva,
                startDt: i.startDt,
                endDt: i.endDt,
                itemStatus: i.itemStatus,
                isEmergency: i.isEmergency,
                remarks: currentRemarks,
              );
            }
            return i;
          }).toList();
        } else {
          updatedItems = widget.parentBooking.generators.map((genId) {
            final isTarget = genId == widget.item.generatorId;
            return BookingItem(
              generatorId: genId,
              capacityKva: widget.item.capacityKva,
              startDt: widget.item.startDt,
              itemStatus: widget.parentBooking.status,
              isEmergency: false,
              remarks: isTarget ? currentRemarks : widget.parentBooking.notes,
            );
          }).toList();
        }

        final updatedBooking = widget.parentBooking.copyWith(
          items: updatedItems,
          notes: updatedItems.length == 1 ? currentRemarks : widget.parentBooking.notes,
        );

        ref.read(bookingProvider.notifier).updateBooking(updatedBooking);
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
      key: ValueKey('${widget.parentBooking.id}_${widget.item.generatorId}_${widget.item.startDt}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: AppColors.surface),
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
        if (widget.parentBooking.items.isNotEmpty) {
          if (widget.parentBooking.items.length <= 1) {
            ref.read(bookingProvider.notifier).deleteBooking(widget.parentBooking.id);
          } else {
            final updatedItems = widget.parentBooking.items.where((i) {
              return !(i.generatorId == widget.item.generatorId && i.startDt == widget.item.startDt);
            }).toList();
            final updatedGenerators = widget.parentBooking.generators.where((g) => g != widget.item.generatorId).toList();
            final updatedBooking = widget.parentBooking.copyWith(
              items: updatedItems,
              generators: updatedGenerators,
            );
            ref.read(bookingProvider.notifier).updateBooking(updatedBooking);
          }
        } else {
          if (widget.parentBooking.generators.length <= 1) {
            ref.read(bookingProvider.notifier).deleteBooking(widget.parentBooking.id);
          } else {
            final updatedGenerators = widget.parentBooking.generators.where((g) => g != widget.item.generatorId).toList();
            final updatedBooking = widget.parentBooking.copyWith(
              generators: updatedGenerators,
            );
            ref.read(bookingProvider.notifier).updateBooking(updatedBooking);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
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
                    widget.item.generatorId,
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
                    widget.item.capacityKva != null ? '${widget.item.capacityKva} kVA' : 'N/A',
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
                    widget.item.startDt,
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
                filled: true,
                fillColor: AppColors.background,
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
