import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SecureScreenManager {
  static const MethodChannel _channel = MethodChannel('com.ledger.app/secure');
  static VoidCallback? _onScreenshotCallback;
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshotTaken') {
        _onScreenshotCallback?.call();
      }
    });
  }

  static void registerScreenshotCallback(VoidCallback callback) {
    _ensureInitialized();
    _onScreenshotCallback = callback;
  }

  static void unregisterScreenshotCallback() {
    _onScreenshotCallback = null;
  }

  static Future<void> enableSecureMode() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (e) {
      debugPrint('Failed to enable secure mode: $e');
    }
  }

  static Future<void> disableSecureMode() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (e) {
      debugPrint('Failed to disable secure mode: $e');
    }
  }
}
