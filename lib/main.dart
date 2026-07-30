import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/preferences/app_preferences.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferences are loaded before the first frame so the saved theme applies
  // immediately — no flash of the wrong brightness on launch.
  await AppPreferences.init();

  // Builds the object graph and restores any persisted session, so the app
  // knows whether it is signed in before it decides what to show.
  await configureDependencies();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(NimmysCrmApp(themeController: ThemeController()));
}
