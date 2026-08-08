import 'package:flutter/material.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:go_router/go_router.dart';
import 'branded_splash_screen.dart';
import 'splash_view_mode.dart';


/// Launch screen: holds the brand animation, then routes on the stored session.
///
/// Signed in goes straight to the dashboard; everything else — no token, or a
/// session check that failed — lands on login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  final splashViewModel = locator<SplashViewModel>();

  /// How long the brand stays on screen regardless of how fast the session
  /// lookup answers — reading secure storage takes milliseconds, and routing
  /// that quickly would flash the splash rather than show it.
  static const Duration _brandHold = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _routeOnSession();
  }

  //  Init Function
  Future<void> _routeOnSession() async {
    // Concurrent, not sequential: the hold and the lookup overlap, so a slow
    // keychain read costs nothing on top of the 3 seconds already being spent.
    await Future.wait<void>(<Future<void>>[
      splashViewModel.fetchIsUserLogin(),
      Future<void>.delayed(_brandHold),
    ]);

    if (!mounted) {
      return;
    }

    final isLoggedIn =
        splashViewModel.checkIsUserLoginUIState?.status == Status.SUCCESS &&
        splashViewModel.checkIsUserLoginUIState?.data == true;

    // `go`, not `push`: the splash must not sit under the next screen where a
    // back gesture could return to it.
    context.go(isLoggedIn ? AppRouteName.home : AppRouteName.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedSplashScreen();
  }
}
