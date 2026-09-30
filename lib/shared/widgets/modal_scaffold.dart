import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'backdrop_blur_overlay.dart';

/// A floating centered modal scaffold container that supports animations
/// and drag-to-dismiss gesture support.
class ModalScaffold extends StatefulWidget {
  /// The title displayed in the modal header.
  final String title;

  /// The scrollable or main content of the modal.
  final Widget body;

  /// Optional footer widget (typically sticky actions like Save/Cancel).
  final Widget? footer;

  /// Callback triggered when the close button is pressed or gesture dismisses it.
  final VoidCallback onClose;

  /// Controls the visibility of the modal layout.
  final bool isVisible;

  /// Creates a [ModalScaffold].
  const ModalScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    required this.onClose,
    this.isVisible = true,
  });

  @override
  State<ModalScaffold> createState() => _ModalScaffoldState();
}

class _ModalScaffoldState extends State<ModalScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _backdropOpacity;
  late Animation<Offset> _slideOffset;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _backdropOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideOffset = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.isVisible) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(ModalScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        setState(() {
          _dragOffset = 0.0;
        });
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset += details.delta.dy;
        if (_dragOffset < 0) _dragOffset = 0.0;
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffset > 150.0 || velocity > 800.0) {
      widget.onClose();
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop overlay
        AnimatedBuilder(
          animation: _backdropOpacity,
          builder: (context, child) {
            return BackdropBlurOverlay(
              isVisible: widget.isVisible,
              onTap: widget.onClose,
              opacity: _backdropOpacity.value,
            );
          },
        ),

        // Centered modal content card
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.mobileGutter),
            child: SlideTransition(
              position: _slideOffset,
              child: Transform.translate(
                offset: Offset(0.0, _dragOffset),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 10),
                          blurRadius: 30,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag gesture handle area
                        GestureDetector(
                          onVerticalDragUpdate: _handleVerticalDragUpdate,
                          onVerticalDragEnd: _handleVerticalDragEnd,
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                width: 40,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 40), // Balance for close button
                                    Expanded(
                                      child: Text(
                                        widget.title,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: widget.onClose,
                                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Scrollable Body
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20.0),
                            child: widget.body,
                          ),
                        ),

                        // Sticky Footer
                        if (widget.footer != null)
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                            ),
                            child: widget.footer!,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
