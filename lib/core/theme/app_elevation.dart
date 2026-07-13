import 'package:flutter/material.dart';

/// Centralized Elevation levels and BoxShadow configurations.
abstract final class AppElevation {
  /// Level 0: Flat (borders only)
  static const level0 = <BoxShadow>[];

  /// Level 1: Raised (subtle, stats cards/interactive cards)
  static final level1 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Level 2: Floating (FAB, elevated buttons)
  static final level2 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Level 3: Overlay (tooltips, dropdowns, active FAB on press)
  static final level3 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Level 4: Modal (modals, bottom sheets)
  static final level4 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Level 5: Drawer (side drawers, full overlays)
  static final level5 = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
