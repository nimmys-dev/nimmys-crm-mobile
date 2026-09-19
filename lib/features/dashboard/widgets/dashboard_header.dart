import 'package:flutter/material.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/utils/app_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_gradient_header.dart';

/// Dashboard hero: menu, wordmark title, notifications and profile avatar.
class DashboardHeader extends StatefulWidget {
  const DashboardHeader({
    super.key,
    required this.userInitials,
    required this.greeting,
    required this.userName,
    required this.dashboardText,
    this.notificationCount = 0,
    this.onMenuTap,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final String dashboardText;
  final String userInitials;
  final String greeting;
  final String userName;
  final int notificationCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  Future<SecuredSharedPreferences> _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return SecuredSharedPreferences(prefs);
  }

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
                FutureBuilder<String?>(
                  future: _getPrefs().then(
                    (prefs) => prefs.get(AppString.sessionKey.userType),
                  ),
                  builder: (context, snapshot) {
                    final role = (snapshot.data ?? '').toLowerCase();

                    final canShowMenu = role == 'admin' || role == 'manager';

                    if (!canShowMenu) {
                      return const SizedBox.shrink();
                    }

                    return AppHeaderIconButton(
                      icon: Icons.menu_rounded,
                      onTap: widget.onMenuTap,
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.dashboardText,
                    style: context.type.screenTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppHeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  badgeCount: widget.notificationCount,
                  onTap: widget.onNotificationsTap,
                ),
                const SizedBox(width: AppSpacing.xs),
                AppAvatar(
                  initials: widget.userInitials,
                  onTap: widget.onAvatarTap,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
