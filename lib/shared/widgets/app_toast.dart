import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum ToastType { success, warning, error, info }

/// A custom top toast notification system matching the design system guidelines.
/// Slides down from the top, displays icon and message, and auto-dismisses.
class AppToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext? context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final targetContext = context ?? AppRouter.navigatorKey.currentContext;
    if (targetContext == null) return;

    // Remove any currently active toast immediately
    final activeEntry = _currentEntry;
    if (activeEntry != null && activeEntry.mounted) {
      activeEntry.remove();
    }
    _currentEntry = null;

    final overlayState = Overlay.of(targetContext);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == overlayEntry) {
            _currentEntry = null;
          }
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    _currentEntry = overlayEntry;
    overlayState.insert(overlayEntry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    if (mounted) {
      await _controller.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final IconData icon;
    final Color iconColor;

    switch (widget.type) {
      case ToastType.success:
        backgroundColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF059669);
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF059669);
        break;
      case ToastType.warning:
        backgroundColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFD97706);
        break;
      case ToastType.error:
        backgroundColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFDC2626);
        icon = Icons.error_outline;
        iconColor = const Color(0xFFDC2626);
        break;
      case ToastType.info:
        backgroundColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFCBD5E1);
        icon = Icons.info_outline;
        iconColor = AppColors.primary;
        break;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.05),
                      offset: Offset(1, 2),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
