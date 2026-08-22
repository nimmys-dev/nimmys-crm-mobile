import 'dart:async';

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
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../utils/toast_messages.dart';
import '../authentication/cubit/session/session_cubit.dart';
import 'cubit/staff/staff_cubit.dart';
import 'model/delete_staff_model.dart';
import 'model/staff_list_model.dart';

/// Staff list — every team member, newest first, from `GET /api/staff`.
///
/// Paginated ten at a time: the next page is fetched as the list nears its end
/// rather than behind a "load more" button, so scrolling is uninterrupted.
class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  /// How close to the bottom the list gets before the next page is requested.
  /// Roughly two rows, which is enough for the fetch to land before the user
  /// reaches the end.
  static const double _loadMoreThreshold = 240;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StaffCubit>().getStaffList();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // The cubit drops the call when there is no next page or one is already
      // in flight, so firing this on every scroll frame is safe.
      context.read<StaffCubit>().loadMoreStaff();
    }
  }

  Future<void> _refresh() async {
    await context.read<StaffCubit>().getStaffList(refresh: true);
  }

  void _searchStaff([String? query]) {
    _searchDebounce?.cancel();
    context.read<StaffCubit>().getStaffList(search: query ?? _searchController.text);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        if (mounted) {
          _searchStaff(value);
        }
      },
    );
  }

  /// Opens Staff Creation by route, so the permission guard runs.
  ///
  /// No refresh here: [StaffCubit.createStaff] reloads the list itself the
  /// moment the API accepts the new staff member, which keeps the list correct
  /// even when creation was started somewhere other than this screen. Doing it
  /// in both places would just fire the call twice.
  void _openCreateStaff() {
    context.push(AppRouteName.staffCreate);
  }

  /// Confirms before calling the API — deleting a staff account is
  /// permanent, and this is the only confirmation gate it gets.
  Future<void> _confirmAndDelete(StaffListItem staff) async {
    final int? id = staff.id;
    if (id == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.palette.surface,
          title: Text(
            'Delete ${staff.name ?? 'this staff member'}?',
            style: dialogContext.type.cardTitle,
          ),
          content: Text(
            'This permanently removes their account. This cannot be undone.',
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
              child: Text(
                'Delete',
                style: dialogContext.type.link.copyWith(color: AppColors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }
    await context.read<StaffCubit>().deleteStaff(id);
  }

  /// Fires once per attempt — the row's own spinner is driven separately by
  /// `state.deletingStaffId`, this only owns the toast.
  void _onDeleteStaffStateChanged(BuildContext context, StaffState state) {
    final UIState<DeleteStaffSuccess>? uiState = state.deleteStaffUIState;
    switch (uiState?.status) {
      case Status.SUCCESS:
        ToastMessages.success(
          message: uiState?.data?.message ?? 'Staff deleted successfully.',
        );
        context.read<StaffCubit>().resetDeleteStaffState();
      case Status.ERROR:
        ToastMessages.error(
          message:
              uiState?.errorType?.getText(context) ??
              'Could not delete staff, Please try again later',
        );
        context.read<StaffCubit>().resetDeleteStaffState();
      case Status.LOADING:
      case Status.INITIAL:
      case null:
        break;
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
          final bool canCreate = session.role.canCreateStaff;
          final bool canDelete = session.role.canDeleteStaff;

          return Scaffold(
            backgroundColor: context.palette.canvas,
            body: Column(
              children: <Widget>[
                Expanded(
                  child: BlocConsumer<StaffCubit, StaffState>(
                    // Everything else this cubit does (list pagination, branch
                    // loading elsewhere) emits too, and none of it should
                    // replay the delete toast.
                    listenWhen: (StaffState previous, StaffState current) =>
                        previous.deleteStaffUIState?.status !=
                        current.deleteStaffUIState?.status,
                    listener: _onDeleteStaffStateChanged,
                    builder: (BuildContext context, StaffState state) {
                      return _StaffListBody(
                        state: state,
                        canCreate: canCreate,
                        canDelete: canDelete,
                        scrollController: _scrollController,
                        onRefresh: _refresh,
                        onCreate: _openCreateStaff,
                        onRetry: _refresh,
                        onDelete: _confirmAndDelete,
                        searchController: _searchController,
                        onSearchChanged: _onSearchChanged,
                        onSearchSubmitted: _searchStaff,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Picks between the list and its loading / error / empty stand-ins.
///
/// Only the *first* load gets the full-screen treatments — once there are rows
/// on screen they stay there, and a failed refresh or a failed next page leaves
/// the list intact rather than replacing it with an error.
class _StaffListBody extends StatelessWidget {
  const _StaffListBody({
    required this.state,
    required this.canCreate,
    required this.canDelete,
    required this.scrollController,
    required this.onRefresh,
    required this.onCreate,
    required this.onRetry,
    required this.onDelete,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
  });

  final StaffState state;
  final bool canCreate;
  final bool canDelete;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;
  final Future<void> Function() onRetry;
  final Future<void> Function(StaffListItem staff) onDelete;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    final List<StaffListItem> staff = state.staffList;
    final Status? status = state.staffListUIState?.status;

    Widget content;
    if (staff.isEmpty && status == Status.LOADING) {
      content = const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
        ),
      );
    } else if (staff.isEmpty && status == Status.ERROR) {
      content = StaffListMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load staff',
        message:
            state.staffListUIState?.errorType?.getText(context) ??
            'Something went wrong. Please try again.',
        actionLabel: 'Retry',
        actionIcon: Icons.refresh_rounded,
        onAction: onRetry,
      );
    } else if (staff.isEmpty) {
      content = StaffListMessage(
        icon: Icons.groups_outlined,
        title: state.staffSearchQuery.isEmpty ? 'No staff yet' : 'No staff found',
        message: state.staffSearchQuery.isEmpty
            ? (canCreate
                  ? 'Add your first team member to get started.'
                  : 'No team members have been added yet.')
            : 'No staff match "${state.staffSearchQuery}".',
        actionLabel: state.staffSearchQuery.isEmpty && canCreate ? 'Add Staff' : null,
        actionIcon: Icons.person_add_alt_1_rounded,
        onAction: canCreate ? () async => onCreate() : null,
      );
    } else {
      final int? total = state.staffPagination?.total;
      content = RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.red,
        child: ListView.builder(
          controller: scrollController,
          // A list shorter than the viewport is not scrollable by default, and an
          // unscrollable list cannot be pulled to refresh.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: AppSpacing.gutter,
            right: AppSpacing.gutter,
            top: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          // One extra row for the count caption, one for the footer.
          itemCount: staff.length + 2,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return StaffListCount(loaded: staff.length, total: total);
            }
            if (index == staff.length + 1) {
              return StaffListFooter(
                isLoading: state.isLoadingMoreStaff,
                hasMore: state.staffPagination?.hasNextPage ?? false,
              );
            }
            final StaffListItem item = staff[index - 1];
            return StaffListTile(
              staff: item,
              onTap: item.id == null
                  ? null
                  : () => context.push(AppRouteName.staffDetailsFor(item.id!)),
              onDelete: canDelete && item.id != null
                  ? () => onDelete(item)
                  : null,
              isDeleting: item.id != null && state.deletingStaffId == item.id,
            );
          },
        ),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.xs,
          ),
          child: AppSearchField(
            hint: 'Search name, code, phone or email',
            controller: searchController,
            onChanged: onSearchChanged,
            onSubmit: onSearchSubmitted,
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

/// "Showing 8 of 8" strip above the rows.
class StaffListCount extends StatelessWidget {
  const StaffListCount({super.key, required this.loaded, this.total});

  final int loaded;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final String label = total == null
        ? '$loaded staff'
        : 'Showing $loaded of $total staff';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Row(
        children: <Widget>[
          Icon(Icons.groups_outlined, size: 15, color: context.palette.muted),
          const SizedBox(width: 5),
          Text(label, style: context.type.caption),
        ],
      ),
    );
  }
}

/// One staff member.
class StaffListTile extends StatelessWidget {
  const StaffListTile({
    super.key,
    required this.staff,
    this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  final StaffListItem staff;
  final VoidCallback? onTap;

  /// Null hides the delete button entirely — used both when the signed-in
  /// role cannot delete staff and when the row has no id to delete by.
  final VoidCallback? onDelete;

  /// True while this specific row's delete is in flight. A separate flag
  /// rather than a shared loading bool because only one row at a time is ever
  /// deleting — see `StaffState.deletingStaffId`.
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final String? phone = staff.phone;
    final String? email = staff.email;

    return AppSectionCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              StaffListAvatar(staff: staff),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      staff.name ?? 'Unnamed',
                      style: context.type.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (staff.employeeCode != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        staff.employeeCode!,
                        style: context.type.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        AppTag(
                          label: (staff.role ?? 'staff').toUpperCase(),
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
                    // Seeded accounts come back with neither, so the block
                    // collapses instead of leaving an empty gap.
                    if (phone != null && phone.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 7),
                      StaffListMetaRow(icon: Icons.call_outlined, value: phone),
                    ],
                    if (email != null && email.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      StaffListMetaRow(
                        icon: Icons.email_outlined,
                        value: email,
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                StaffDeleteButton(
                  isDeleting: isDeleting,
                  onPressed: isDeleting ? null : onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing delete action on [StaffListTile]. Same circular-icon-button shape
/// used across the app (see `LeadCallButton`), swapped for a small spinner
/// while [isDeleting].
class StaffDeleteButton extends StatelessWidget {
  const StaffDeleteButton({
    super.key,
    required this.isDeleting,
    this.onPressed,
    this.size = 36,
  });

  final bool isDeleting;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.redWash,
      shape: CircleBorder(side: BorderSide(color: context.palette.redBorder)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: isDeleting
                ? SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
                    ),
                  )
                : const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.red,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Staff photo, falling back to initials.
///
/// The fallback covers three cases with one widget: no `photo_url` at all, a
/// URL still downloading, and a URL that fails — a broken-image glyph in a
/// team list reads as a bug.
class StaffListAvatar extends StatelessWidget {
  const StaffListAvatar({super.key, required this.staff, this.size = 48});

  final StaffListItem staff;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = AppAvatar(
      initials: staff.initials,
      size: size,
      tone: AppAvatarTone.onLight,
    );

    if (!staff.hasPhoto) {
      return fallback;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: staff.photoUrl!,
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

/// Icon + value line inside [StaffListTile].
class StaffListMetaRow extends StatelessWidget {
  const StaffListMetaRow({super.key, required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: context.palette.faint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: context.type.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Bottom of the list: the next-page spinner, or the end of the list.
class StaffListFooter extends StatelessWidget {
  const StaffListFooter({
    super.key,
    required this.isLoading,
    required this.hasMore,
  });

  final bool isLoading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
            ),
          ),
        ),
      );
    }
    if (hasMore) {
      return const SizedBox(height: AppSpacing.md);
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Text(
          "That's everyone",
          style: context.type.caption.copyWith(color: context.palette.faint),
        ),
      ),
    );
  }
}

/// Full-screen stand-in for the empty and failed states.
class StaffListMessage extends StatelessWidget {
  const StaffListMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: context.palette.redWash,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.red),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: context.type.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: context.type.bodyMuted,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppOutlineButton(
                label: actionLabel!,
                icon: actionIcon,
                expand: false,
                onPressed: () => onAction!(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
