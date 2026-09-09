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
import 'package:nimmys_crm/helpers/app_version_helper.dart';
import 'package:nimmys_crm/routing/app_route_name.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/utils/toast_messages.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({super.key});

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
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
    ThemeScope.maybeOf(context);

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
                      _version.isEmpty ? 'Version' : 'Version $_version',
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
                      icon: Icons.business_outlined,
                      activeIcon: Icons.business_rounded,
                      title: 'Closed Leads',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRouteName.closedLeads);
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
                      icon: Icons.lock_outline_rounded,
                      activeIcon: Icons.lock_rounded,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.pop(context);
                        context.push(AppRouteName.changePassword);
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
}
