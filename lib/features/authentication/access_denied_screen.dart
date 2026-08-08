import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';

/// Where the router lands anyone who reaches for a screen their role does not
/// have. Deliberately a real screen rather than a silent bounce: a tap that
/// appears to do nothing reads as a bug, and a user who has genuinely been
/// promoted needs to know why they are still being turned away.
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            const AppGradientHeader(
              title: 'Access Restricted',
              eyebrow: 'PERMISSIONS',
              leading: AppBackButton(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.md,
                ),
                children: <Widget>[
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: context.palette.redWash,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 34,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "You don't have access to this screen",
                          style: context.type.cardTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Your account role does not include this area of the '
                          'app. Contact an administrator if you think this is '
                          'a mistake.',
                          style: context.type.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppPrimaryButton(
                          label: 'Back to Dashboard',
                          icon: Icons.home_rounded,
                          onPressed: () => context.go(AppRouteName.home),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
