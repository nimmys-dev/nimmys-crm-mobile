import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nimmys_crm/core/app_initializer.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/multi_bloc.dart';
import 'package:nimmys_crm/routing/app_routes.dart';
import 'package:nimmys_crm/service/hasInternet/has_internet_connection.dart';
import 'package:nimmys_crm/utils/extensions/state_extension.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  @override
  void initState() {
    super.initState();
    initFun();
  }

  void initFun() => frameCallback(() async {
    await HasInternetConnection().checkConnectivity();
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocWrapper(
      child: MaterialApp.router(
        title: 'NIMMYS CRM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}