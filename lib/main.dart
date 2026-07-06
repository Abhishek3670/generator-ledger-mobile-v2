import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/haptic_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HapticService.initialize();
  runApp(const ProviderScope(child: LedgerApp()));
}
