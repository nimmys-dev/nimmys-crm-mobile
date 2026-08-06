import 'package:firebase_core/firebase_core.dart';
// // // // // // // import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/firebase_options.dart';


///  App Initialization Function
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialization
  // Must create the [DEFAULT] app — Crashlytics/Messaging/Analytics below all read
  // FirebaseX.instance, which resolves the default app rather than a named one.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Dependency Injection
  initLocator();
}
