import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Custom [Page] that slides the child page in from the right.
/// Used for standard directional screen navigation (forward push, backward pop).
/// Supports edge-swipe back gestures.
class SlideRightTransitionPage<T> extends Page<T> {
  final Widget child;
  final bool swipeBack;

  const SlideRightTransitionPage({
    required this.child,
    this.swipeBack = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return _SlideRightPageRoute<T>(
      settings: this,
      child: child,
      swipeBack: swipeBack,
    );
  }
}

class _SlideRightPageRoute<T> extends CupertinoPageRoute<T> {
  final Widget child;
  final bool swipeBack;

  _SlideRightPageRoute({
    required this.child,
    required this.swipeBack,
    super.settings,
  }) : super(
          builder: (context) => child,
        );

  @override
  bool get popGestureEnabled {
    if (!swipeBack) return false;
    if (animation == null) return false;
    return super.popGestureEnabled;
  }
}

/// Custom [CustomTransitionPage] that slides the child modal up from the bottom,
/// accompanied by a backdrop fade animation.
class ModalSlideUpTransitionPage<T> extends CustomTransitionPage<T> {
  ModalSlideUpTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    Duration duration = const Duration(milliseconds: 300),
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          opaque: false,
          barrierColor: const Color(0x80000000), // Black with 0.5 opacity (0x80 = 128 = 0.5 * 255)
          barrierDismissible: true,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOutCubic));

            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeIn));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        );
}

/// Helper PageRoute Builders for traditional [Navigator] push navigation.
class PageTransitions {
  /// Slide right route transition builder.
  static Route<T> slideRight<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        );
      },
    );
  }

  /// Slide up modal route transition builder.
  static Route<T> slideUpModal<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: const Color(0x80000000), // Black with 0.5 opacity
      barrierDismissible: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOutCubic));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        );
      },
    );
  }
}
