import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Service that handles incoming deep links via the `gensetapp://` custom URL
/// scheme and translates them into [GoRouter] navigation calls.
///
/// Supported deep links:
/// - `gensetapp://generator/:id` → `/generators/:id`
/// - `gensetapp://billing`       → `/billing`
/// - `gensetapp://bookings`      → `/bookings`
/// - `gensetapp://vendors`       → `/vendors`
class DeepLinkService {
  DeepLinkService({
    required GoRouter router,
  }) : _router = router;

  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// A pending deep link destination that arrived while the user was
  /// unauthenticated. The auth redirect callback should check this after
  /// successful login and navigate here instead of the default `/dashboard`.
  String? pendingDeepLink;

  /// Initialize the deep link listener.
  ///
  /// Handles two cases:
  /// 1. **Cold start**: The app was launched via a deep link (initial link).
  /// 2. **Warm start**: A deep link arrives while the app is already running.
  Future<void> init() async {
    // Handle cold-start deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Failed to get initial link: $e');
    }

    // Handle warm-start deep links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint('DeepLinkService: Link stream error: $error');
      },
    );
  }

  /// Parse a `gensetapp://` URI and navigate to the corresponding route.
  void _handleDeepLink(Uri uri) {
    final route = parseDeepLink(uri);
    if (route == null) {
      debugPrint('DeepLinkService: Unrecognized deep link: $uri');
      return;
    }

    debugPrint('DeepLinkService: Navigating to $route from $uri');

    // Store as pending in case auth redirect intercepts
    pendingDeepLink = route;

    // Use go() which builds the correct back-stack based on the route tree.
    // For `/generators/:id`, GoRouter knows it's a child of `/generators`,
    // which is inside the StatefulShellRoute — so back navigation returns
    // to the generators list, not out of the app.
    _router.go(route);
  }

  /// Parse a deep link URI into a GoRouter path.
  ///
  /// Returns `null` if the URI doesn't match any known deep link pattern.
  ///
  /// This is a pure function exposed for unit testing.
  static String? parseDeepLink(Uri uri) {
    // Only handle gensetapp:// scheme
    if (uri.scheme != 'gensetapp') return null;

    // The host is the first path segment in custom scheme URIs
    // e.g., gensetapp://generator/GEN-100 → host='generator', pathSegments=['GEN-100']
    // e.g., gensetapp://billing → host='billing', pathSegments=[]
    final host = uri.host;
    final pathSegments = uri.pathSegments;

    switch (host) {
      case 'generator':
        if (pathSegments.isNotEmpty) {
          final id = pathSegments.first;
          return '/generators/$id';
        }
        // No ID provided — fall back to generators list
        return '/generators';

      case 'billing':
        return '/billing';

      case 'bookings':
        return '/bookings';

      case 'vendors':
        return '/vendors';

      default:
        return null;
    }
  }

  /// Clear the pending deep link after it has been consumed (e.g., after
  /// successful login redirect).
  String? consumePendingDeepLink() {
    final link = pendingDeepLink;
    pendingDeepLink = null;
    return link;
  }

  /// Dispose of the link listener subscription.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
