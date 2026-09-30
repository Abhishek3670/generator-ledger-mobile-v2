import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle consistent haptic feedback across the application.
///
/// Integrates with SharedPreferences to allow users to toggle feedback in the settings.
class HapticService {
  static bool _isEnabled = true;

  /// Returns whether haptic feedback is currently enabled.
  static bool get isEnabled => _isEnabled;

  /// Initializes the service by reading user preferences.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('haptic_enabled') ?? true;
    } catch (_) {
      _isEnabled = true;
    }
  }

  /// Sets the enabled state of the haptic service and persists it.
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('haptic_enabled', enabled);
    } catch (_) {}
  }

  /// Trigger a light impact feedback (e.g. standard button presses).
  static void light() {
    if (_isEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Trigger a medium impact feedback (e.g. non-destructive list swipes or actions).
  static void medium() {
    if (_isEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Trigger a heavy impact feedback (e.g. destructive actions like delete).
  static void heavy() {
    if (_isEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Trigger selection feedback (e.g. tab switches, picker scrolls, slider adjustments).
  static void selection() {
    if (_isEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Trigger success feedback (double tap effect).
  static void success() {
    if (_isEnabled) {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 50), () {
        HapticFeedback.lightImpact();
      });
    }
  }

  /// Trigger error feedback (heavy double tap effect).
  static void error() {
    if (_isEnabled) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
      });
    }
  }
}
