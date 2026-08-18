import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// // // // // // // import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nimmys_crm/core/preferences/app_preferences.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/firebase_options.dart';
import 'package:nimmys_crm/service/push_notification/notification_service.dart';
import 'package:nimmys_crm/utils/app_global_variables.dart';


///  App Initialization Function
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Base URL and any API credentials live in .env.dev. Nothing that talks to
  // the network can run before this: EnvironmentVariables throws on an empty
  // base URL, so loading it late turns every request into a launch crash.
  await dotenv.load(fileName: ".env.dev");

  // Remember-me and the saved email are read synchronously during build on the
  // login screen, so the store has to be open before the first frame.
  await AppPreferences.init();

  // Firebase Initialization
  // Must create the [DEFAULT] app — Crashlytics/Messaging/Analytics below all read
  // FirebaseX.instance, which resolves the default app rather than a named one.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Background/terminated FCM messages are delivered on a fresh isolate that only
  // ever runs `main`, so the handler has to be attached on this path to exist at
  // all — registering it inside NotificationService would never take effect there.
  FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );

  // Dependency Injection
  initLocator();

  // Channels, permissions, the FCM token and the foreground/tap handlers. The
  // GetIt registration alone is lazy, so without this call the service is never
  // constructed and no listener is ever attached.
  //
  // Not awaited: fetching the token is a network round trip that can take seconds
  // on a cold connection and would otherwise hold back the first frame. Every step
  // inside `init` catches its own failures, so a denied permission cannot take
  // down launch.
  unawaited(
    locator<NotificationService>().init(
      navigatorKey,
      locator<SecuredSharedPreferences>(),
    ),
  );
}
