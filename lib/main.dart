import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/app_navigator.dart';
import 'core/notification/notification_service.dart';
import 'core/preferences/app_preferences.dart';
import 'core/storage/secured_shared_preferences.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferences are loaded before the first frame so the saved theme applies
  // immediately — no flash of the wrong brightness on launch.
  await AppPreferences.init();

  // Firebase first: every FCM call below depends on it, including the one in
  // the background isolate. Registering the background handler here rather
  // than inside NotificationService is deliberate — the isolate is spawned
  // fresh for each message and only ever runs `main`, so the handler has to be
  // attached on this path to exist at all.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );

  // Builds the object graph and restores any persisted session, so the app
  // knows whether it is signed in before it decides what to show.
  await configureDependencies();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Channels, permissions, the FCM token and the foreground/tap handlers.
  //
  // Not awaited: fetching the token is a network round trip that can take
  // seconds on a cold connection, and blocking here would hold back the first
  // frame for it. Nothing this sets up is needed until a message arrives, and
  // a tap that cold-started the app is replayed by `getInitialMessage()`
  // whenever the handler happens to be ready. Every step inside `init` catches
  // its own failures, so a denied permission cannot take down launch.
  unawaited(
    NotificationService().init(
      appNavigatorKey,
      sl<SecuredSharedPreferences>(),
    ),
  );

  runApp(NimmysCrmApp(themeController: ThemeController()));
}
