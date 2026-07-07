import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/haptic_service.dart';
import 'core/services/user_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HapticService.initialize();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const LedgerApp(),
  ));
}
