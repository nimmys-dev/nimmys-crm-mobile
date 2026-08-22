import 'package:flutter/material.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
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

  Future<void> _routeOnSession() async {
    try {
      await Future.wait<void>([
        splashViewModel.fetchIsUserLogin(),
        locator<SessionCubit>().loadSession(),
        Future<void>.delayed(_brandHold),
      ]);

      if (!mounted) return;

      final isLoggedIn =
          splashViewModel.checkIsUserLoginUIState?.status == Status.SUCCESS &&
          splashViewModel.checkIsUserLoginUIState?.data == true;

      context.go(isLoggedIn ? AppRouteName.home : AppRouteName.signIn);
    } catch (e, stack) {
      // Log the error to see what's wrong
      print('Splash error: $e\n$stack');
      // Optionally navigate to login on error
      if (mounted) context.go(AppRouteName.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const BrandedSplashScreen();
  }
}
