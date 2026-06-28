import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'backdrop_blur_overlay.dart';

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
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Backdrop overlay
        BackdropBlurOverlay(
          isVisible: _isOpen,
          onTap: _toggleMenu,
        ),

        // Menu items stack
        Padding(
          padding: const EdgeInsets.only(bottom: 64.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              return _buildItem(item, index);
            }),
          ),
        ),

        // Primary FAB
        FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: _isOpen ? AppColors.primaryDark : AppColors.accent,
          foregroundColor: _isOpen ? Colors.white : AppColors.primary,
          shape: const StadiumBorder(),
          elevation: 4,
          child: Icon(_isOpen ? widget.expandedIcon : widget.collapsedIcon),
        ),
      ],
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
                  backgroundColor: Colors.white,
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
