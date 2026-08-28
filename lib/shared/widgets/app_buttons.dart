import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Full-width gradient call-to-action.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 54,
    this.tone = AppButtonTone.red,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final AppButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    final Gradient gradient = tone == AppButtonTone.red
        ? AppColors.actionGradient
        : context.palette.inkGradient;

    return Opacity(
      opacity: isEnabled ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  (tone == AppButtonTone.red ? AppColors.red : AppColors.black)
                      .withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, size: 19, color: AppColors.white),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: context.type.button.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppButtonTone { red, ink }

/// Bordered secondary action.
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 46,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.palette.redBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 17, color: AppColors.red),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: context.type.link.copyWith(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact pill button used for inline actions such as "Edit" / "+ Add Call".
class AppPillButton extends StatelessWidget {
  const AppPillButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.tone = AppIconChipStyle.outlined,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconChipStyle tone;

  @override
  Widget build(BuildContext context) {
    final bool isFilled = tone == AppIconChipStyle.filled;

    return Material(
      color: isFilled ? AppColors.red : context.palette.redWash,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 14,
                color: isFilled ? AppColors.white : AppColors.red,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isFilled ? AppColors.white : AppColors.red,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppIconChipStyle { filled, outlined }

/// Circular back button shown on every screen that is not a root destination.
///
/// App Store review rejects screens a user can enter but not leave, so this is
/// deliberately always visible and always tappable: it pops the route when
/// there is one, and otherwise falls back to [onPressed]. The glyph follows the
/// host platform — a chevron on iOS, an arrow elsewhere.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.tone = Brightness.dark});

  final VoidCallback? onPressed;

  /// [Brightness.dark] renders for a dark header, [Brightness.light] for paper.
  final Brightness tone;

  /// GoRouter owns the page stack, so it is asked first.
  ///
  /// `Navigator.maybePop` calls `ModalRoute.willPop()`, which asserts its modal
  /// scope is still mounted. Popping the raw Navigator underneath GoRouter
  /// leaves GoRouter's route list out of step with it, and the next back press
  /// then hits that assertion — `'scope != null'` — as a red screen.
  ///
  /// Falls back to `maybePop` when there is no router above this button, or
  /// nothing for the router to pop: screens pushed imperatively still need a
  /// working back button.
  static void _goBack(BuildContext context) {
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bool onDark = tone == Brightness.dark;
    final bool isCupertino =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS;

    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: onDark
            ? AppColors.white.withValues(alpha: 0.14)
            : context.palette.inkWash,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed ?? () => _goBack(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              isCupertino
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_back_rounded,
              size: isCupertino ? 18 : 20,
              color: onDark ? AppColors.white : context.palette.ink,
            ),
          ),
        ),
      ),
    );
  }
}
