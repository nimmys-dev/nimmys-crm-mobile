import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/preview/screen_catalog_screen.dart';
import 'features/splash/splash_screen.dart';

/// Root of the NIMMYS CRM UI kit.
///
/// Publishes the [ThemeController] to the tree and rebuilds [MaterialApp]
/// whenever the user switches between light, dark and system.
class NimmysCrmApp extends StatelessWidget {
  const NimmysCrmApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            title: 'NIMMYS CRM',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            home: const AppEntryPoint(),
          );
        },
      ),
    );
  }
}

/// Shows the splash, then hands off to the screen catalog.
///
/// Swap [ScreenCatalogScreen] for `LoginScreen` (or your own router) when the
/// real navigation layer is added.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onCompleted: () => setState(() => _splashDone = true),
      );
    }
    return const ScreenCatalogScreen();
  }
}
