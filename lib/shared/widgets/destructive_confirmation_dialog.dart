import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_dimensions.dart';
import 'modal_scaffold.dart';

/// A modal confirmation dialog for destructive actions.
/// Requires the user to type a confirmation word (e.g. "DELETE") to enable confirmation.
class DestructiveConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final String confirmationWord;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isVisible;

  const DestructiveConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
    this.confirmText = 'DELETE',
    this.cancelText = 'CANCEL',
    this.confirmationWord = 'DELETE',
    this.isVisible = true,
  });

  @override
  State<DestructiveConfirmationDialog> createState() =>
      _DestructiveConfirmationDialogState();
}

class _DestructiveConfirmationDialogState
    extends State<DestructiveConfirmationDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isConfirmEnabled = false;

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateConfirmation);
    _focusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_validateConfirmation);
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _validateConfirmation() {
    final matches = _controller.text.trim() == widget.confirmationWord;
    if (matches != _isConfirmEnabled) {
      setState(() {
        _isConfirmEnabled = matches;
      });
    }
  }

  void _handleConfirm() {
    if (_isConfirmEnabled) {
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onCancel();
          } else if (event.logicalKey == LogicalKeyboardKey.enter && _isConfirmEnabled) {
            _handleConfirm();
          }
        }
      },
      child: ModalScaffold(
        title: widget.title,
        isVisible: widget.isVisible,
        onClose: widget.onCancel,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'To confirm, type "${widget.confirmationWord}" in the box below:',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.functionalRadius),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.confirmationWord,
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppDimensions.functionalRadius)),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppDimensions.functionalRadius)),
                    borderSide: BorderSide(color: AppColors.border, width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppDimensions.functionalRadius)),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: AppTypography.bodyMedium,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) {
                  if (_isConfirmEnabled) {
                    _handleConfirm();
                  }
                },
              ),
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                widget.cancelText,
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isConfirmEnabled ? _handleConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                widget.confirmText,
                style: AppTypography.labelCaps.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
