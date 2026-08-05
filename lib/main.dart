import 'package:flutter/material.dart';
import 'package:nimmys_crm/core/app_initializer.dart';
import 'package:nimmys_crm/multi_bloc.dart';
import 'package:nimmys_crm/routing/app_routes.dart';
import 'package:nimmys_crm/service/hasInternet/has_internet_connection.dart';
import 'package:nimmys_crm/utils/app_theme_style.dart';
import 'package:nimmys_crm/utils/extensions/state_extension.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    initFun();
    super.initState();
  }

  void initFun() => frameCallback(() async {
    await HasInternetConnection().checkConnectivity();
    // await authRepo.signOut();
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocWrapper(
      child: MaterialApp.router(
        title: "Update Your App Name",
        debugShowCheckedModeBanner: true,
        theme: AppThemeStyle.appTheme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
