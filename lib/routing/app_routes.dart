import 'package:flutter/material.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';
import 'package:nimmys_crm/utils/default_screen.dart';
import 'package:go_router/go_router.dart';

class AppRoutes{
  AppRoutes._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRouteName.splash,
    navigatorKey: navigatorKey,
    routes: <RouteBase>[

      // Splash
      GoRoute(
        path: AppRouteName.splash,
        builder: (BuildContext context, GoRouterState state) {
          return  Container();
        },
      ),

      // Default Screen
      GoRoute(
        path: AppRouteName.notFound,
        builder: (BuildContext context, GoRouterState state) {
          return const DefaultScreen();
        },
      ),

    ],
  );


}