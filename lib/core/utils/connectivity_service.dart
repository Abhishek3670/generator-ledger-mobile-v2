import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((event) {
    // Handle both List<ConnectivityResult> (v6+) and ConnectivityResult (v5)
    dynamic e = event;
    if (e is List) {
      if (e.isEmpty) return ConnectivityResult.none;
      return e.first as ConnectivityResult;
    }
    return e as ConnectivityResult;
  });
});
