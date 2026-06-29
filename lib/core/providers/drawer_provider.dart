import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track whether the side drawer is open or closed.
final drawerOpenProvider = StateProvider<bool>((ref) => false);
