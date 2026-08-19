import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:nimmys_crm/core/theme/app_colors.dart';
import 'package:nimmys_crm/core/theme/app_dimens.dart';
import 'package:nimmys_crm/core/theme/app_theme.dart';
import 'package:nimmys_crm/core/theme/theme_controller.dart';
import 'package:nimmys_crm/dependency_injection/locator.dart';
import 'package:nimmys_crm/enum/status.dart';
import 'package:nimmys_crm/features/authentication/cubit/logout/logout_cubit.dart';
import 'package:nimmys_crm/features/authentication/cubit/session/session_cubit.dart';
import 'package:nimmys_crm/features/leads/cubit/leads/leads_cubit.dart';
import 'package:nimmys_crm/features/profile/cubit/profile/profile_cubit.dart';
import 'package:nimmys_crm/features/staff/cubit/staff/staff_cubit.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  Future<void> _confirmAndLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.palette.surface,
          title: Text('Log out?', style: dialogContext.type.cardTitle),
          content: Text(
            'You will need your email and password to sign back in.',
            style: dialogContext.type.bodyMuted,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: dialogContext.type.link.copyWith(
                  color: dialogContext.palette.muted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Log out', style: dialogContext.type.link),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<LogoutCubit>().logout();
  }

  // Called when logout succeeds or fails
  void _onLogoutStateChanged(BuildContext context, LogoutState state) {
    final Status? status = state.logoutUIState?.status;
    if (status != Status.SUCCESS && status != Status.ERROR) {
      return;
    }

    final GoRouter router = GoRouter.of(context);

    if (status == Status.SUCCESS) {
      ToastMessages.success(
        message: state.logoutUIState?.data?.message ?? 'Logout successful',
      );
    } else {
      ToastMessages.error(
        message:
            state.logoutUIState?.errorType?.getText(context) ??
            'Signed out on this device',
      );
    }

    // Clear all session‑scoped cubits
    context.read<LogoutCubit>().resetLogoutState();
    context.read<ProfileCubit>().resetProfileState();
    locator<SessionCubit>().clearSession();
    locator<StaffCubit>().resetStaffState();
    locator<LeadsCubit>().resetLeadsState();

    // Close the drawer, then navigate to sign‑in
    Navigator.of(context).pop(); // close drawer
    router.go(AppRouteName.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final type = context.type;
    final controller = ThemeScope.maybeOf(context);
    final themeMode = controller?.themeMode ?? ThemeMode.system;

    return BlocListener<LogoutCubit, LogoutState>(
      listener: _onLogoutStateChanged,
      child: Drawer(
        backgroundColor: palette.surface,
        child: SafeArea(
          child: Column(
            children: [
              // ============================================================
              // HEADER
              // ============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nimmy\'s CRM',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ============================================================
              // MENU
              // ============================================================
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.business_outlined,
                      activeIcon: Icons.business_rounded,
                      title: 'Company Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRouteName.companyDetails);
                      },
                    ),

                    Divider(
                      height: AppSpacing.md,
                      thickness: 0.5,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: palette.line,
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        // Navigate to settings
                      },
                    ),

                    Divider(
                      height: AppSpacing.md,
                      thickness: 0.5,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: palette.line,
                    ),

                    // ======================================================
                    // THEME
                    // ======================================================
                    _buildThemeTile(context, themeMode: themeMode),
                  ],
                ),
              ),

              // ============================================================
              // LOGOUT
              // ============================================================
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: BlocBuilder<LogoutCubit, LogoutState>(
                  builder: (BuildContext context, LogoutState state) {
                    final bool isLoggingOut =
                        state.logoutUIState?.status == Status.LOADING;
                    return AppPrimaryButton(
                      label: 'LOGOUT',
                      icon: Icons.logout_rounded,
                      isLoading: isLoggingOut,
                      onPressed: isLoggingOut
                          ? null
                          : () => _confirmAndLogout(context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // DRAWER ITEM
  // ========================================================================

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    final type = context.type;

    return ListTile(
      leading: Icon(icon, color: palette.slate, size: 24),
      title: Text(
        title,
        style: type.body.copyWith(
          color: palette.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
    );
  }

  // ========================================================================
  // THEME TILE
  // ========================================================================

  Widget _buildThemeTile(BuildContext context, {required ThemeMode themeMode}) {
    final palette = context.palette;
    final type = context.type;

    final String label;
    final IconData icon;

    switch (themeMode) {
      case ThemeMode.light:
        label = 'Light mode';
        icon = Icons.light_mode_rounded;
        break;

      case ThemeMode.dark:
        label = 'Dark mode';
        icon = Icons.dark_mode_rounded;
        break;

      case ThemeMode.system:
        label = 'System default';
        icon = Icons.brightness_auto_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showThemeSelector(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.inkWash,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: palette.ink, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: type.body.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: type.caption.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // THEME BOTTOM SHEET
  // ========================================================================

  void _showThemeSelector(BuildContext context) {
    final palette = context.palette;
    final type = context.type;

    final controller = ThemeScope.maybeOf(context);

    if (controller == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose theme',
                  style: type.body.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select how NIMMYS CRM should look.',
                  style: type.body.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 18),

                // System
                _buildThemeOption(
                  context: sheetContext,
                  icon: Icons.brightness_auto_rounded,
                  title: 'System',
                  subtitle: 'Follow device appearance',
                  selected: controller.themeMode == ThemeMode.system,
                  onTap: () {
                    controller.setThemeMode(ThemeMode.system);
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 10),

                // Light
                _buildThemeOption(
                  context: sheetContext,
                  icon: Icons.light_mode_rounded,
                  title: 'Light',
                  subtitle: 'Use light appearance',
                  selected: controller.themeMode == ThemeMode.light,
                  onTap: () {
                    controller.setThemeMode(ThemeMode.light);
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 10),

                // Dark
                _buildThemeOption(
                  context: sheetContext,
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark',
                  subtitle: 'Use dark appearance',
                  selected: controller.themeMode == ThemeMode.dark,
                  onTap: () {
                    controller.setThemeMode(ThemeMode.dark);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;
    final type = context.type;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? palette.redWashSoft : palette.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? palette.redBorder : palette.line,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected ? palette.redWash : palette.inkWash,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.red : palette.slate,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: type.body.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: type.caption.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Container(
                        key: const ValueKey('selected'),
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('unselected'),
                        width: 24,
                        height: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
