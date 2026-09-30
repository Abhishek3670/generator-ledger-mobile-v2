import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'backdrop_blur_overlay.dart';

/// A reusable draggable bottom sheet shell used for form data entry.
///
/// Supports three snap points (30%, 60%, 90% of screen height), dragging to dismiss,
/// and tap-outside-to-dismiss behavior. Integrated with [onDismissAttempt] to handle
/// confirmation dialogs (e.g. for unsaved changes/drafts).
class DraggableFormSheet extends StatefulWidget {
  /// The title displayed in the modal header.
  final String title;

  /// The uppercase category label displayed above the title (e.g., "BOOKINGS").
  final String category;

  /// The main form content.
  final Widget child;

  /// Optional footer widget containing action buttons.
  final Widget? footer;

  /// Callback triggered when the sheet is successfully closed.
  final VoidCallback onClose;

  /// Optional callback to intercept dismissal (e.g., to show a discard confirmation).
  ///
  /// Returns `true` to allow dismissal, `false` to cancel it.
  final Future<bool> Function()? onDismissAttempt;

  /// Optional action widget(s) displayed in the header next to the close button.
  final List<Widget>? actions;

  const DraggableFormSheet({
    super.key,
    required this.title,
    required this.category,
    required this.child,
    this.footer,
    required this.onClose,
    this.onDismissAttempt,
    this.actions,
  });

  @override
  State<DraggableFormSheet> createState() => _DraggableFormSheetState();
}

class _DraggableFormSheetState extends State<DraggableFormSheet> {
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetSizeChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    if (!mounted) return;
    final size = _sheetController.size;
    // Detect when dragged down past the collapsed (0.3) snap point
    if (size < 0.25 && !_isDismissing) {
      _isDismissing = true;
      _handleDismissAttempt();
    }
  }

  Future<void> _handleDismissAttempt() async {
    if (widget.onDismissAttempt != null) {
      final shouldDismiss = await widget.onDismissAttempt!();
      if (shouldDismiss) {
        widget.onClose();
      } else {
        // Reset dismissing flag and animate back to default half-expanded state
        setState(() {
          _isDismissing = false;
        });
        // Wait a frame to ensure state is clean
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _sheetController.animateTo(
              0.6,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop blur / dim overlay
        BackdropBlurOverlay(
          isVisible: true,
          onTap: () async {
            if (!_isDismissing) {
              _isDismissing = true;
              await _handleDismissAttempt();
            }
          },
        ),

        // Draggable Scrollable Bottom Sheet container
        Align(
          alignment: Alignment.bottomCenter,
          child: DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.6,
            minChildSize: 0.2, // slightly below 0.3 to allow drag-down detection
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.3, 0.6, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background, // bg-background (#fafafa)
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: const Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                    left: BorderSide(color: AppColors.border, width: 1),
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pill drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border, // #cbd5e1
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Left-aligned header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category.toUpperCase(),
                                  style: AppTypography.labelCaps.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    letterSpacing: 2.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.title,
                                  style: AppTypography.headlineMedium.copyWith(
                                    color: AppColors.primary,
                                    fontFamily: 'SpaceGrotesk',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.actions != null) ...[
                            ...widget.actions!,
                            const SizedBox(width: 12),
                          ],
                          IconButton(
                            onPressed: () async {
                              if (!_isDismissing) {
                                _isDismissing = true;
                                  await _handleDismissAttempt();
                              }
                            },
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: AppColors.border,
                      height: 1,
                      thickness: 1,
                    ),

                    // Scrollable content area wrapping the form child
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: widget.child,
                      ),
                    ),

                    // Sticky footer for action buttons
                    if (widget.footer != null) ...[
                      const Divider(
                        color: AppColors.border,
                        height: 1,
                        thickness: 1,
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: AppColors.surface,
                        child: widget.footer,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
