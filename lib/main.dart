import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nimmys_crm/core/app_initializer.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/core/theme/theme_controller.dart';
import 'package:nimmys_crm/multi_bloc.dart';
import 'package:nimmys_crm/routing/app_routes.dart';
import 'package:nimmys_crm/service/hasInternet/has_internet_connection.dart';
import 'package:nimmys_crm/utils/extensions/state_extension.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock app orientation to portrait (up)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// Owns the light/dark choice for the whole app. Handed down through
  /// [ThemeScope] so the login screen's Appearance selector and the header
  /// toggle both drive the same value — and it is persisted, so it survives
  /// a restart.
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    initFun();
    super.initState();
  }

  void initFun() => frameCallback(() async {
    await HasInternetConnection().checkConnectivity();
    // await authRepo.signOut();
  });

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocWrapper(
      child: ThemeScope(
        controller: _themeController,
        // Rebuilds on every notifyListeners, which is what re-themes the app the
        // instant the selector changes rather than on the next route push.
        child: AnimatedBuilder(
          animation: _themeController,
          builder: (BuildContext context, Widget? _) {
            return MaterialApp.router(
              title: "NIMMYS CRM",
              debugShowCheckedModeBanner: true,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _themeController.themeMode,
              routerConfig: AppRoutes.router,
            );
          },
        ),
      ),
    );
  }
}
