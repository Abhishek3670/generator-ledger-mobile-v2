import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/routing/app_router.dart';
import 'core/services/haptic_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/user_preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HapticService.initialize();
  await NotificationService().initialize();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const LedgerApp(),
  ));

  // Initialize deep link handling after the app (and router) are created.
  // This must happen after runApp so the GoRouter instance exists.
  await AppRouter.initDeepLinks();
}
