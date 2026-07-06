import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/haptic_service.dart';

/// A wrapper widget that equips cards with slide-to-reveal actions.
///
/// Swiping right reveals a red "Delete" action. Swiping left reveals an amber "Modify" action.
class SwipeActionCard extends StatelessWidget {
  /// The card widget contained inside the slide wrapper.
  final Widget child;

  /// Callback triggered when the "Modify" action is tapped.
  final VoidCallback? onModify;

  /// Callback triggered when the "Delete" action is tapped.
  final VoidCallback? onDelete;

  /// Creates a [SwipeActionCard].
  const SwipeActionCard({
    super.key,
    required this.child,
    this.onModify,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(hashCode),
      startActionPane: onDelete == null
          ? null
          : ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticService.medium();
                    onDelete?.call();
                  },
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                ),
              ],
            ),
      endActionPane: onModify == null
          ? null
          : ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticService.light();
                    onModify?.call();
                  },
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  icon: Icons.edit_outlined,
                  label: 'Modify',
                ),
              ],
            ),
      child: child,
    );
  }
}
