import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

abstract final class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.dashboard,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Generator Ledger'))),
      ),
    ],
  );
}
