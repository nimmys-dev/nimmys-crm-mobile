import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Curved black-to-red header used at the top of every interior screen.
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.eyebrow,
    this.bottom,
    this.height = 118,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  /// Small tracked label shown above the title.
  final String? eyebrow;

  /// Optional content pinned below the title row, inside the header.
  final Widget? bottom;

  final double height;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: const AppHeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        padding: EdgeInsets.only(
          top: topInset + AppSpacing.xs,
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: height - AppSpacing.xxl,
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    leading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (eyebrow != null) ...<Widget>[
                          Text(eyebrow!, style: context.type.headerEyebrow),
                          const SizedBox(height: AppSpacing.xxs),
                        ],
                        Text(
                          title,
                          style: context.type.screenTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            if (bottom != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Gives the header its soft concave sweep along the bottom edge.
class AppHeaderCurveClipper extends CustomClipper<Path> {
  const AppHeaderCurveClipper();

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..lineTo(0, size.height - 34)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height,
        size.width * 0.58,
        size.height - 12,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height - 24,
        size.width,
        size.height - 40,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Round translucent icon button designed to sit on the gradient header.
class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badgeCount,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// When non-null and greater than zero a red count bubble is drawn.
  final int? badgeCount;

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool hasBadge = badgeCount != null && badgeCount! > 0;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.22),
                ),
              ),
              child: Icon(icon, color: AppColors.white, size: size * 0.5),
            ),
            if (hasBadge)
              Positioned(
                right: -2,
                top: -2,
                child: AppCountBadge(count: badgeCount!),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small red bubble showing an unread/pending count.
class AppCountBadge extends StatelessWidget {
  const AppCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: AppColors.redBright,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          height: 1.1,
        ),
      ),
    );
  }
}
