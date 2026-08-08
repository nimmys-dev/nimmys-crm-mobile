import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/app_permission.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../data/ui_state/ui_state.dart';
import '../../enum/status.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../utils/constant_variables.dart';
import '../authentication/cubit/session/session_cubit.dart';
import '../profile/profile_sheet.dart';
import 'cubit/staff/staff_cubit.dart';
import 'model/staff_details_model.dart';
import 'model/store_success_model.dart';
import 'model/user_role_model.dart';
import 'staff_list_screen.dart';

/// Staff Details — one team member's full record, from
/// `GET /api/view-staff/{id}`.
///
/// Read-only: editing happens on [AppRouteName.staffEdit], which is
/// [StaffCreationScreen] in its edit mode. Reached from a row on the staff
/// list.
class StaffDetailsScreen extends StatefulWidget {
  const StaffDetailsScreen({super.key, required this.staffId});

  final int staffId;

  @override
  State<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends State<StaffDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Branches and roles are only needed to turn `shop_id`/`role` into the
    // names this screen shows — `getBranches`/`getUserRoles` skip the call
    // when another staff screen already loaded them this session. The record
    // itself always fetches fresh: see `StaffCubit.getStaffDetails`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StaffCubit>()
          ..getStaffDetails(widget.staffId)
          ..getBranches()
          ..getUserRoles();
      }
    });
  }

  Future<void> _openEdit() async {
    final Object? result = await context.push<Object?>(
      AppRouteName.staffEditFor(widget.staffId),
    );
    // Any non-null result means Save ran successfully — re-fetch so this
    // screen shows what was actually saved rather than trusting the form's
    // own copy of it.
    if (result != null && mounted) {
      context.read<StaffCubit>().getStaffDetails(widget.staffId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: BlocBuilder<SessionCubit, SessionState>(
        builder: (BuildContext context, SessionState session) {
          final bool canEdit = session.role.canEditStaff;

          return Scaffold(
            backgroundColor: context.palette.canvas,
            body: Column(
              children: <Widget>[
                AppGradientHeader(
                  title: 'Staff Details',
                  eyebrow: 'TEAM',
                  leading: const AppBackButton(),
                  actions: <Widget>[
                    if (canEdit)
                      AppHeaderIconButton(
                        icon: Icons.edit_outlined,
                        onTap: _openEdit,
                      ),
                  ],
                ),
                Expanded(
                  child: BlocBuilder<StaffCubit, StaffState>(
                    builder: (BuildContext context, StaffState state) {
                      return _StaffDetailsBody(
                        state: state,
                        onRetry: () => context
                            .read<StaffCubit>()
                            .getStaffDetails(widget.staffId),
                      );
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Picks between the loading / error / content states of the details call.
class _StaffDetailsBody extends StatelessWidget {
  const _StaffDetailsBody({required this.state, required this.onRetry});

  final StaffState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final UIState<StaffDetailsSuccess>? detailsState =
        state.staffDetailsUIState;
    final StaffDetailsData? staff = detailsState?.data?.data;

    if (staff == null && detailsState?.status == Status.LOADING) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      );
    }

    if (staff == null) {
      return StaffListMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load staff details',
        message:
            detailsState?.errorType?.getText(context) ??
            'Something went wrong. Please try again.',
        actionLabel: 'Retry',
        actionIcon: Icons.refresh_rounded,
        onAction: () async => onRetry(),
      );
    }

    final List<StoreResponseData> branches =
        state.branchesUIState?.data?.activeBranches ?? <StoreResponseData>[];
    final List<UserRoleOption> roles =
        state.userRolesUIState?.data?.selectableRoles ?? <UserRoleOption>[];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.md,
      ),
      children: <Widget>[
        AppSectionCard(
          child: Column(
            children: <Widget>[
              StaffDetailsAvatar(staff: staff),
              const SizedBox(height: AppSpacing.sm),
              Text(staff.name ?? 'Unnamed', style: context.type.pageHeading),
              if (staff.employeeCode != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(staff.employeeCode!, style: context.type.bodyMuted),
              ],
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  AppTag(
                    label: _roleLabel(staff.role, roles).toUpperCase(),
                    icon: Icons.badge_outlined,
                  ),
                  AppTag(
                    label: staff.isActive ? 'ACTIVE' : 'INACTIVE',
                    icon: staff.isActive
                        ? Icons.check_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    isAccent: false,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: 'Contact'),
              const SizedBox(height: AppSpacing.xs),
              ProfileDetailRow(
                icon: Icons.call_outlined,
                label: 'Mobile',
                value: staff.phone,
              ),
              ProfileDetailRow(
                icon: Icons.add_ic_call_outlined,
                label: 'Alternate',
                value: staff.alternatePhone,
              ),
              ProfileDetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: staff.email,
              ),
            ],
          ),
        ),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: 'Employment'),
              const SizedBox(height: AppSpacing.xs),
              ProfileDetailRow(
                icon: Icons.storefront_outlined,
                label: 'Branch',
                value: _branchLabel(staff.shopId, branches),
              ),
              ProfileDetailRow(
                icon: Icons.event_outlined,
                label: 'Joining Date',
                value: staff.joiningDate == null
                    ? null
                    : AppDateField.format(staff.joiningDate!),
              ),
              ProfileDetailRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Salary',
                value: _formatCurrency(staff.salary),
              ),
              ProfileDetailRow(
                icon: Icons.groups_outlined,
                label: 'Lead Management',
                value: staff.leadModuleAccess == true ? 'Enabled' : 'Disabled',
              ),
            ],
          ),
        ),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: 'Increment'),
              const SizedBox(height: AppSpacing.xs),
              ProfileDetailRow(
                icon: Icons.event_repeat_rounded,
                label: 'Next Increment',
                value: staff.incrementDate == null
                    ? null
                    : AppDateField.format(staff.incrementDate!),
              ),
              ProfileDetailRow(
                icon: Icons.trending_up_rounded,
                label: 'Increment Amount',
                value: _formatCurrency(staff.incrementAmount),
              ),
              ProfileDetailRow(
                icon: Icons.notifications_active_outlined,
                label: 'Reminder',
                value: staff.incrementNotification == true ? 'On' : 'Off',
              ),
              if (staff.description != null && staff.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Description', style: context.type.bodyMuted),
                      const SizedBox(height: 3),
                      Text(staff.description!, style: context.type.body),
                    ],
                  ),
                ),
            ],
          ),
        ),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppSectionHeader(title: 'Record Information'),
              const SizedBox(height: AppSpacing.xs),
              ProfileDetailRow(
                icon: Icons.tag_outlined,
                label: 'Staff ID',
                value: staff.id?.toString(),
              ),
              ProfileDetailRow(
                icon: Icons.schedule_outlined,
                label: 'Created',
                value: staff.createdAt == null
                    ? null
                    : AppDateField.format(staff.createdAt!),
              ),
              ProfileDetailRow(
                icon: Icons.update_outlined,
                label: 'Last Updated',
                value: staff.updatedAt == null
                    ? null
                    : AppDateField.format(staff.updatedAt!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The branch's name for [shopId], falling back to a numbered placeholder
  /// when the branch list has not loaded (or no longer contains it — an
  /// inactive branch, say) rather than a blank row for a shop that plainly is
  /// assigned.
  String? _branchLabel(int? shopId, List<StoreResponseData> branches) {
    if (shopId == null) {
      return null;
    }
    for (final StoreResponseData branch in branches) {
      if (branch.id == shopId) {
        return branch.name;
      }
    }
    return 'Shop #$shopId';
  }

  /// The role's display label, matched against `GET /api/user-roles`. Falls
  /// back to the raw API value so the tag is never blank while roles load.
  String _roleLabel(String? role, List<UserRoleOption> roles) {
    if (role == null || role.isEmpty) {
      return 'staff';
    }
    for (final UserRoleOption option in roles) {
      if (option.value == role) {
        return option.displayLabel;
      }
    }
    return role;
  }

  /// `"20000.00"` → `"₹20,000"`-style whole amount, `"1234.50"` keeps its
  /// fraction. Null/unparsable input renders as the usual em dash via
  /// [ProfileDetailRow].
  String? _formatCurrency(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final double? value = double.tryParse(raw);
    if (value == null) {
      return raw;
    }
    final String amount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$indianCurrencySymbol$amount';
  }
}

/// Large centred photo for the details header, falling back to initials.
class StaffDetailsAvatar extends StatelessWidget {
  const StaffDetailsAvatar({super.key, required this.staff, this.size = 88});

  final StaffDetailsData staff;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = AppAvatar(
      initials: staff.initials,
      size: size,
      tone: AppAvatarTone.solid,
    );

    final String? url = staff.photoUrl;
    if (url == null || url.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (BuildContext context, String url) => fallback,
        errorWidget: (BuildContext context, String url, Object error) =>
            fallback,
      ),
    );
  }
}
