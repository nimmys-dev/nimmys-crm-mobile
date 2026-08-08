import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../dependency_injection/locator.dart';
import '../../enum/status.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../utils/toast_messages.dart';
import '../authentication/cubit/logout/logout_cubit.dart';
import '../authentication/cubit/session/session_cubit.dart';
import '../staff/cubit/staff/staff_cubit.dart';
import 'cubit/profile/profile_cubit.dart';
import 'model/profile_model.dart';

/// Presents [ProfileSheet], re-providing the cubits from the parent context.
///
/// The sheet is built by the root navigator, whose context sits *above*
/// MultiBlocWrapper — without re-providing, `context.read` inside the sheet
/// throws ProviderNotFoundException.
Future<void> showProfileSheet(BuildContext context) {
  final ProfileCubit profileCubit = context.read<ProfileCubit>();
  final LogoutCubit logoutCubit = context.read<LogoutCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<LogoutCubit>.value(value: logoutCubit),
        ],
        child: const ProfileSheet(),
      );
    },
  );
}

/// Account sheet behind the dashboard avatar: who is signed in, and the way out.
///
/// Open it with [showProfileSheet] rather than constructing it directly.
class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  @override
  void initState() {
    super.initState();
    // Opening the sheet is also a refresh: the dashboard's copy may be minutes
    // old, and this is the surface where the details are actually read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileCubit>().getProfile(force: true);
      }
    });
  }

  Future<void> _confirmAndLogout() async {
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

    if (confirmed != true || !mounted) {
      return;
    }
    await context.read<LogoutCubit>().logout();
  }

  /// Fires once per attempt. Both outcomes leave the app: the device session is
  /// cleared either way, so staying on the dashboard would only show stale data
  /// behind requests that now 401.
  void _onLogoutStateChanged(BuildContext context, LogoutState state) {
    final Status? status = state.logoutUIState?.status;
    if (status != Status.SUCCESS && status != Status.ERROR) {
      return;
    }

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

    // Clear every cubit that outlives the session before leaving, so the next
    // sign-in starts blank. Session and staff are reached through the locator
    // rather than the sheet's providers: they are the same singletons, and this
    // sheet's UI never reads them, so re-providing them just to clear them
    // would be plumbing for its own sake.
    context.read<LogoutCubit>().resetLogoutState();
    context.read<ProfileCubit>().resetProfileState();
    locator<SessionCubit>().clearSession();
    locator<StaffCubit>().resetStaffState();

    Navigator.of(context).pop();
    GoRouter.of(context).go(AppRouteName.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutCubit, LogoutState>(
      listener: _onLogoutStateChanged,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ProfileSheetGrabber(),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (BuildContext context, ProfileState state) {
                  return ProfileSheetBody(
                    status: state.profileUIState?.status,
                    user: state.profileUIState?.data?.user,
                    errorMessage: state.profileUIState?.errorType?.getText(
                      context,
                    ),
                    onRetry: () =>
                        context.read<ProfileCubit>().getProfile(force: true),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<LogoutCubit, LogoutState>(
                builder: (BuildContext context, LogoutState state) {
                  final bool isLoggingOut =
                      state.logoutUIState?.status == Status.LOADING;
                  return AppPrimaryButton(
                    label: 'LOGOUT',
                    icon: Icons.logout_rounded,
                    isLoading: isLoggingOut,
                    onPressed: isLoggingOut ? null : _confirmAndLogout,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The drag handle at the top of the sheet.
class ProfileSheetGrabber extends StatelessWidget {
  const ProfileSheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: context.palette.line,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

/// Loading / loaded / failed states of the profile call in one widget, so the
/// sheet body never renders a half-populated card.
class ProfileSheetBody extends StatelessWidget {
  const ProfileSheetBody({
    super.key,
    required this.status,
    required this.user,
    this.errorMessage,
    this.onRetry,
  });

  final Status? status;
  final ProfileUser? user;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // A cached profile stays on screen while a refresh runs — replacing it with
    // a spinner would make every sheet open flicker.
    if (user == null && status == Status.LOADING) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: CircularProgressIndicator(color: AppColors.red),
      );
    }

    final ProfileUser? profile = user;
    if (profile == null) {
      return Column(
        children: <Widget>[
          Icon(
            Icons.person_off_outlined,
            size: 34,
            color: context.palette.muted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorMessage ?? 'Profile could not be loaded',
            textAlign: TextAlign.center,
            style: context.type.bodyMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppOutlineButton(label: 'Retry', onPressed: onRetry),
        ],
      );
    }

    return Column(
      children: <Widget>[
        AppAvatar(
          initials: profile.initials,
          size: 64,
          tone: AppAvatarTone.solid,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(profile.name ?? '—', style: context.type.pageHeading),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppTag(label: (profile.role ?? 'staff').toUpperCase()),
            const SizedBox(width: AppSpacing.xs),
            AppTag(
              label: (profile.status ?? 'unknown').toUpperCase(),
              icon: profile.isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.pause_circle_outline_rounded,
              isAccent: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileDetailRow(
          icon: Icons.badge_outlined,
          label: 'Employee code',
          value: profile.employeeCode,
        ),
        ProfileDetailRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: profile.email,
        ),
        ProfileDetailRow(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile.phone,
        ),
        ProfileDetailRow(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          value: profile.shopId?.toString(),
        ),
      ],
    );
  }
}

/// One labelled row of the profile card. Renders an em dash rather than hiding
/// the row when the API sends null, so the shape of the record stays readable.
class ProfileDetailRow extends StatelessWidget {
  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String? shown = value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: context.palette.muted),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: context.type.bodyMuted),
          const Spacer(),
          Flexible(
            child: Text(
              (shown == null || shown.isEmpty) ? '—' : shown,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
