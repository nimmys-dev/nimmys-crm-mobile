import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_gradient_header.dart';
import '../../../shared/widgets/theme_toggle_button.dart';

/// Dashboard hero: menu, wordmark title, notifications and profile avatar.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userInitials,
    required this.greeting,
    required this.userName,
    this.notificationCount = 0,
    this.onMenuTap,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final String userInitials;
  final String greeting;
  final String userName;
  final int notificationCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: const AppHeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        padding: EdgeInsets.only(
          top: topInset + AppSpacing.sm,
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.huge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppHeaderIconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('DASHBOARD', style: context.type.screenTitle),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppHeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: notificationCount,
                  onTap: onNotificationsTap,
                ),
                const SizedBox(width: AppSpacing.xs),
                AppAvatar(initials: userInitials, onTap: onAvatarTap),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DashboardGreeting(greeting: greeting, userName: userName),
          ],
        ),
      ),
    );
  }
}

/// "Good morning, Abin" block inside the dashboard header.
class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.greeting,
    required this.userName,
  });

  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(greeting.toUpperCase(), style: context.type.headerEyebrow),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                userName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'ONLINE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
