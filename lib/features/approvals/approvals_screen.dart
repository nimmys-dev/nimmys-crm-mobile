import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../utils/toast_messages.dart';

/// Where an approval request sits.
enum ApprovalStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const ApprovalStatus(this.label);

  final String label;

  static List<String> get labels =>
      ApprovalStatus.values.map((ApprovalStatus s) => s.label).toList();
}

/// One duty submitted for a manager's sign-off.
class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.detail,
    required this.requestedBy,
    required this.requestedAt,
    this.status = ApprovalStatus.pending,
  });

  final String id;
  final String title;
  final String detail;
  final String requestedBy;
  final DateTime requestedAt;
  final ApprovalStatus status;

  ApprovalRequest copyWith({ApprovalStatus? status}) => ApprovalRequest(
    id: id,
    title: title,
    detail: detail,
    requestedBy: requestedBy,
    requestedAt: requestedAt,
    status: status ?? this.status,
  );
}

/// Approvals — duties waiting on a manager's decision.
///
/// The destination behind the dashboard's "Approval Pending" counter, which
/// only admin and manager see; the route carries the same `viewApprovals`
/// permission so the two cannot disagree.
///
/// DATA — sample rows. This project has no approvals endpoint (`ApiUrls` covers
/// auth, profile and staff only), and the counter this screen opens from is
/// hard-coded for the same reason. Approve/reject update local state so the
/// flow is reviewable; wire them to the API when one exists.
class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  late List<ApprovalRequest> _requests = <ApprovalRequest>[
    ApprovalRequest(
      id: '1',
      title: 'Leave request — 2 days',
      detail: 'Personal leave covering the Ettumanoor counter shift.',
      requestedBy: 'Sijo',
      requestedAt: _daysAgo(0),
    ),
    ApprovalRequest(
      id: '2',
      title: 'Discount approval — Sigma 85mm',
      detail: '8% off list for a repeat customer closing today.',
      requestedBy: 'Abin Babu',
      requestedAt: _daysAgo(0),
    ),
    ApprovalRequest(
      id: '3',
      title: 'Stock transfer to Hill Palace',
      detail: 'Move three Sony bodies to cover the weekend demand.',
      requestedBy: 'Mathew Thomas',
      requestedAt: _daysAgo(1),
    ),
    ApprovalRequest(
      id: '4',
      title: 'Overtime — stock audit',
      detail: 'Four hours beyond the closing shift.',
      requestedBy: 'Thomas John',
      requestedAt: _daysAgo(3),
      status: ApprovalStatus.approved,
    ),
    ApprovalRequest(
      id: '5',
      title: 'Advance against salary',
      detail: 'Requested outside the monthly window.',
      requestedBy: 'Sijo',
      requestedAt: _daysAgo(6),
      status: ApprovalStatus.rejected,
    ),
  ];

  static DateTime _daysAgo(int days) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days, 9, 30);
  }

  int _tabIndex = 0;

  ApprovalStatus get _filter => ApprovalStatus.values[_tabIndex];

  List<ApprovalRequest> get _visible => _requests
      .where((ApprovalRequest request) => request.status == _filter)
      .toList();

  void _decide(ApprovalRequest request, ApprovalStatus decision) {
    setState(() {
      _requests = _requests
          .map(
            (ApprovalRequest item) =>
                item.id == request.id ? item.copyWith(status: decision) : item,
          )
          .toList();
    });
    if (decision == ApprovalStatus.approved) {
      ToastMessages.success(message: '${request.title} approved');
    } else {
      ToastMessages.alert(message: '${request.title} rejected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ApprovalRequest> requests = _visible;
    final int pendingCount = _requests
        .where((ApprovalRequest r) => r.status == ApprovalStatus.pending)
        .length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            const AppGradientHeader(
              title: 'Approvals',
              eyebrow: 'TEAM',
              leading: AppBackButton(),
              actions: <Widget>[AppAvatar(initials: 'AB')],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.md,
                AppSpacing.gutter,
                AppSpacing.sm,
              ),
              child: AppSegmentedTabs(
                options: ApprovalStatus.labels,
                selectedIndex: _tabIndex,
                onChanged: (int index) => setState(() => _tabIndex = index),
              ),
            ),
            Expanded(
              child: requests.isEmpty
                  ? ApprovalsEmptyState(status: _filter)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.gutter,
                        right: AppSpacing.gutter,
                        bottom: AppSpacing.xl,
                      ),
                      itemCount: requests.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return ApprovalsCount(
                            count: requests.length,
                            pending: pendingCount,
                            status: _filter,
                          );
                        }
                        final ApprovalRequest request = requests[index - 1];
                        return ApprovalTile(
                          request: request,
                          onApprove: () =>
                              _decide(request, ApprovalStatus.approved),
                          onReject: () =>
                              _decide(request, ApprovalStatus.rejected),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Count strip above the rows.
class ApprovalsCount extends StatelessWidget {
  const ApprovalsCount({
    super.key,
    required this.count,
    required this.pending,
    required this.status,
  });

  final int count;
  final int pending;
  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final String label = status == ApprovalStatus.pending
        ? '$count awaiting your decision'
        : '$count ${status.label.toLowerCase()} · $pending still pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 2),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 15,
            color: context.palette.muted,
          ),
          const SizedBox(width: 5),
          Text(label, style: context.type.caption),
        ],
      ),
    );
  }
}

/// One request, with its decision buttons while it is still pending.
class ApprovalTile extends StatelessWidget {
  const ApprovalTile({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
  });

  final ApprovalRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final bool isPending = request.status == ApprovalStatus.pending;

    return AppSectionCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      accentBorder: isPending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconChip(
                icon: switch (request.status) {
                  ApprovalStatus.pending => Icons.hourglass_top_rounded,
                  ApprovalStatus.approved => Icons.check_circle_outline_rounded,
                  ApprovalStatus.rejected => Icons.cancel_outlined,
                },
                size: 38,
                tone: isPending ? AppIconChipTone.red : AppIconChipTone.ink,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      request.title,
                      style: context.type.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.detail,
                      style: context.type.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        AppTag(
                          label: request.requestedBy,
                          icon: Icons.person_outline_rounded,
                          isAccent: false,
                        ),
                        AppTag(
                          label: AppDateField.format(request.requestedAt),
                          icon: Icons.schedule_rounded,
                          isAccent: false,
                        ),
                        if (!isPending)
                          AppTag(
                            label: request.status.label.toUpperCase(),
                            icon: request.status == ApprovalStatus.approved
                                ? Icons.check_rounded
                                : Icons.close_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppOutlineButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    height: 46,
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Nothing in this tab — an empty pending queue is good news, worded that way.
class ApprovalsEmptyState extends StatelessWidget {
  const ApprovalsEmptyState({super.key, required this.status});

  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String title, String message) = switch (status) {
      ApprovalStatus.pending => (
        Icons.verified_outlined,
        'Nothing to approve',
        'Every request has been dealt with. Nice work.',
      ),
      ApprovalStatus.approved => (
        Icons.check_circle_outline_rounded,
        'No approved requests',
        'Requests you approve will be listed here.',
      ),
      ApprovalStatus.rejected => (
        Icons.cancel_outlined,
        'No rejected requests',
        'Requests you turn down will be listed here.',
      ),
    };

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
          ],
        ),
      ),
    );
  }
}
