import 'package:flutter/material.dart';
import 'package:nimmys_crm/helpers/app_version_helper.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_logo.dart';

/// Brand splash: black stage, red light bloom, logo settling into place.
///
/// [onCompleted] fires once the intro animation and hold have finished so the
/// host can decide where to go next — the screen itself performs no routing.
class BrandedSplashScreen extends StatefulWidget {
  const BrandedSplashScreen({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  State<BrandedSplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<BrandedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _tailFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _markScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.50, curve: Curves.easeOutBack),
      ),
    );
    _markFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.40, curve: Curves.easeOut),
    );
    _wordFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
          ),
        );
    _tailFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );

    _controller.forward().whenComplete(() {
      if (mounted) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.black,
      ),
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const SplashBackdrop(),
            FadeTransition(opacity: _glow, child: const SplashGlow()),
            const SplashCornerAccent(),
            SafeArea(
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _markFade,
                    child: ScaleTransition(
                      scale: _markScale,
                      child: const SplashLogoBadge(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeTransition(
                    opacity: _wordFade,
                    child: SlideTransition(
                      position: _wordSlide,
                      child: const SplashWordmark(),
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _tailFade,
                    child: const SplashProgressBar(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeTransition(
                    opacity: _tailFade,
                    child: const SplashFooter(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Base gradient stage of the splash.
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.splashGradient),
    );
  }
}

/// Warm red bloom behind the logo.
class SplashGlow extends StatelessWidget {
  const SplashGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.28),
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              AppColors.red.withValues(alpha: 0.34),
              AppColors.red.withValues(alpha: 0.10),
              Colors.transparent,
            ],
            stops: const <double>[0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Faint red arcs bleeding in from the screen corners.
class SplashCornerAccent extends StatelessWidget {
  const SplashCornerAccent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -70,
          right: -60,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.red.withValues(alpha: 0.22),
                width: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.06),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded plate framing the brand lockup on the splash.
class SplashLogoBadge extends StatelessWidget {
  const SplashLogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.xl + 4),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.25),
            blurRadius: 44,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const AppLogo(height: 62),
    );
  }
}

/// Rule and product descriptor sitting under the logo.
class SplashWordmark extends StatelessWidget {
  const SplashWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SplashDivider(),
        SizedBox(height: AppSpacing.md),
        Text(
          'CUSTOMER  ·  LEADS  ·  DUTIES',
          style: context.type.splashTagline,
        ),
      ],
    );
  }
}

/// Thin rule with a red centre pip, used under the wordmark.
class SplashDivider extends StatelessWidget {
  const SplashDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 46,
          height: 1,
          color: AppColors.white.withValues(alpha: 0.18),
        ),
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: const BoxDecoration(
            color: AppColors.red,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 46,
          height: 1,
          color: AppColors.white.withValues(alpha: 0.18),
        ),
      ],
    );
  }
}

/// Indeterminate loading rail at the foot of the splash.
class SplashProgressBar extends StatefulWidget {
  const SplashProgressBar({super.key});

  @override
  State<SplashProgressBar> createState() => _SplashProgressBarState();
}

class _SplashProgressBarState extends State<SplashProgressBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: AppColors.white.withValues(alpha: 0.10),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      ),
    );
  }
}

/// Version / ownership line.
class SplashFooter extends StatefulWidget {
  const SplashFooter({super.key});

  @override
  State<SplashFooter> createState() => _SplashFooterState();
}

class _SplashFooterState extends State<SplashFooter> {
  String _version = '';
  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final String version = await AppVersionService.instance.getVersion();

    if (!mounted) return;

    setState(() {
      _version = version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'NIMMYS CRM',
          style: context.type.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.62),
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _version,
          style: context.type.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.30),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
