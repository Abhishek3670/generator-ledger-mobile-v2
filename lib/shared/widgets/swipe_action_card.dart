import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/haptic_service.dart';

/// A wrapper widget that equips cards with slide-to-reveal actions.
///
/// Swiping right (reveals startActionPane) shows a blue "Edit" action.
/// Swiping left (reveals endActionPane) shows a red "Delete" (or "Cancel") action.
class SwipeActionCard extends StatelessWidget {
  /// The card widget contained inside the slide wrapper.
  final Widget child;

  /// Callback triggered when the edit/modify action is tapped.
  final VoidCallback? onModify;

  /// Callback triggered when the delete/cancel action is tapped.
  final VoidCallback? onDelete;

  /// Label for the delete/cancel action. Defaults to 'Delete'.
  final String deleteLabel;

  /// Label for the edit/modify action. Defaults to 'Edit'.
  final String modifyLabel;

  /// Icon for the delete/cancel action.
  final IconData deleteIcon;

  /// Icon for the edit/modify action.
  final IconData modifyIcon;

  /// Creates a [SwipeActionCard].
  const SwipeActionCard({
    super.key,
    required this.child,
    this.onModify,
    this.onDelete,
    this.deleteLabel = 'Delete',
    this.modifyLabel = 'Edit',
    this.deleteIcon = Icons.delete_outline,
    this.modifyIcon = Icons.edit_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(hashCode),
      // Swiping Right reveals Start Action Pane (Edit)
      startActionPane: onModify == null
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
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  icon: modifyIcon,
                  label: modifyLabel,
                ),
              ],
            ),
      // Swiping Left reveals End Action Pane (Delete/Cancel)
      endActionPane: onDelete == null
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
                  icon: deleteIcon,
                  label: deleteLabel,
                ),
              ],
            ),
      child: child,
    );
  }
}
