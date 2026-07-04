import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';

/// An expandable Floating Action Button (FAB) menu item.
class ExpandableFABItem {
  /// The icon representing this action.
  final IconData icon;

  /// The label displayed next to the icon.
  final String label;

  /// Callback triggered when this action is tapped.
  final VoidCallback onPressed;

  /// Creates an [ExpandableFABItem].
  const ExpandableFABItem({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

/// A Floating Action Button that expands vertically to reveal sub-action options.
///
/// Includes an integrated backdrop blur overlay that triggers during expansion.
class ExpandableFABMenu extends StatefulWidget {
  /// The list of expanding actions.
  final List<ExpandableFABItem> items;

  /// The primary collapsed icon.
  final IconData collapsedIcon;

  /// The primary expanded icon.
  final IconData expandedIcon;

  /// Creates an [ExpandableFABMenu].
  const ExpandableFABMenu({
    super.key,
    required this.items,
    this.collapsedIcon = Icons.add,
    this.expandedIcon = Icons.close,
  });

  @override
  State<ExpandableFABMenu> createState() => _ExpandableFABMenuState();
}

class _ExpandableFABMenuState extends State<ExpandableFABMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _animationController,
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isOpen) {
            _showOverlay();
          }
        });
      } else {
        _animationController.reverse().then((_) {
          if (mounted && !_isOpen) {
            _hideOverlay();
          }
        });
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final rightPadding = screenWidth - (offset.dx + size.width);
            final bottomPadding = screenHeight - (offset.dy + size.height);

            return Stack(
              children: [
                // Full-screen backdrop blur
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleMenu,
                    behavior: HitTestBehavior.opaque,
                    child: FadeTransition(
                      opacity: _animationController,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            color: AppColors.primary.withValues(alpha: 0.20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating menu items and active FAB positioned exactly on top of the original FAB
                Positioned(
                  right: rightPadding,
                  bottom: bottomPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Sub-actions
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: FadeTransition(
                          opacity: _expandAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(widget.items.length, (index) {
                                final item = widget.items[index];
                                return _buildItem(item, index);
                              }),
                            ),
                          ),
                        ),
                      ),
                      
                      // Active/expanded primary FAB
                      FloatingActionButton(
                        onPressed: _toggleMenu,
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 4,
                        child: Icon(widget.expandedIcon),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggleMenu,
      backgroundColor: _isOpen ? AppColors.primaryDark : AppColors.accent,
      foregroundColor: _isOpen ? Colors.white : AppColors.primary,
      shape: const StadiumBorder(),
      elevation: 4,
      child: Icon(_isOpen ? widget.expandedIcon : widget.collapsedIcon),
    );
  }

  Widget _buildItem(ExpandableFABItem item, int index) {
    final step = 1.0 / widget.items.length;
    final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _expandAnimation,
        curve: Interval(
          (widget.items.length - 1 - index) * step,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    return ScaleTransition(
      scale: itemAnimation,
      child: FadeTransition(
        opacity: itemAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.pillRadius),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  item.label,
                  style: AppTypography.labelCaps.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                height: 40,
                child: FloatingActionButton(
                  onPressed: () {
                    _toggleMenu();
                    item.onPressed();
                  },
                  heroTag: 'expandable_item_$index',
                  backgroundColor: (item.label.toLowerCase().contains('add') ||
                          item.label.toLowerCase().contains('create'))
                      ? AppColors.accent
                      : Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  child: Icon(item.icon, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
