import 'package:flutter/material.dart';
import 'package:nimmys_crm/features/authentication/login_screen.dart';
import 'package:nimmys_crm/features/dashboard/dashboard_screen.dart';
import 'package:nimmys_crm/features/preview/screen_catalog_screen.dart';
import 'package:nimmys_crm/features/splash/splash_screen.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';
import 'package:go_router/go_router.dart';

class AppRoutes{
  AppRoutes._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRouteName.splash,
    navigatorKey: navigatorKey,
    routes: <RouteBase>[

      // Splash
      // Decides between home and signIn once the session check completes.
      GoRoute(
        path: AppRouteName.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),

      // Sign In
      GoRoute(
        path: AppRouteName.signIn,
        builder: (BuildContext context, GoRouterState state) {
          // `go` replaces the login entry: once the token is stored, backing
          // into the form would show a screen the user is already past.
          return LoginScreen(
            onSignedIn: () => context.go(AppRouteName.home),
          );
        },
      ),

      // Home
      GoRoute(
        path: AppRouteName.home,
        builder: (BuildContext context, GoRouterState state) {
          return const DashboardScreen();
        },
      ),

      // Default Screen
      // Still the design catalog — every screen in the app reachable in one tap.
      GoRoute(
        path: AppRouteName.notFound,
        builder: (BuildContext context, GoRouterState state) {
          return const ScreenCatalogScreen();
        },
      ),

    ],
  );


}
