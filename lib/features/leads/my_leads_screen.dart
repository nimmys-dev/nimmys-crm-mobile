import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_dialer.dart';
import '../../routing/app_route_name.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_search_field.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import 'domain/entities/lead.dart';

/// My Leads — the enquiries assigned to the signed-in user.
///
/// Filtered by [LeadStatus] rather than a hand-written list of tabs, so the
/// pipeline stages here and the ones the capture screen writes can never drift
/// apart. Tapping a lead opens the existing Lead Details screen.
///
/// DATA — the rows below are sample data. This project has no leads endpoint
/// yet (`ApiUrls` covers auth, profile and staff only) and the dashboard
/// counters that open this screen are hard-coded for the same reason. When a
/// leads API lands, replace [_allLeads] with a cubit following the staff list;
/// the widgets below take a `List<Lead>` and need no changes.
class MyLeadsScreen extends StatefulWidget {
  const MyLeadsScreen({super.key});

  @override
  State<MyLeadsScreen> createState() => _MyLeadsScreenState();
}

class _MyLeadsScreenState extends State<MyLeadsScreen> {
  static final List<Lead> _allLeads = <Lead>[
    Lead(
      id: '1',
      name: 'Sejun',
      mobile: '9961210000',
      status: LeadStatus.negotiating,
      createdAt: _daysAgo(2),
      source: LeadSource.instagram,
      requiredItems: 'Sigma 85mm Lens',
      nextFollowUpAt: _daysAgo(0),
    ),
    Lead(
      id: '2',
      name: 'Abin',
      mobile: '8086140010',
      status: LeadStatus.fresh,
      createdAt: _daysAgo(0),
      source: LeadSource.whatsapp,
      requiredItems: 'Sony Camera',
    ),
    Lead(
      id: '3',
      name: 'Sajeesh',
      mobile: '9842610235',
      status: LeadStatus.contacted,
      createdAt: _daysAgo(4),
      source: LeadSource.call,
      requiredItems: 'Lens Sony',
      nextFollowUpAt: _daysAgo(-2),
    ),
    Lead(
      id: '4',
      name: 'Madhu',
      mobile: '8081616161',
      status: LeadStatus.won,
      createdAt: _daysAgo(9),
      source: LeadSource.facebook,
      requiredItems: 'Mac Mini M4',
    ),
    Lead(
      id: '5',
      name: 'Ranjith',
      mobile: '9847112233',
      status: LeadStatus.qualified,
      createdAt: _daysAgo(1),
      source: LeadSource.instagram,
      requiredItems: 'Manfrotto Tripod',
      nextFollowUpAt: _daysAgo(-1),
    ),
    Lead(
      id: '6',
      name: 'Anitha',
      mobile: '9995540012',
      status: LeadStatus.lost,
      createdAt: _daysAgo(14),
      source: LeadSource.other,
      requiredItems: 'Printer',
    ),
  ];

  static DateTime _daysAgo(int days) {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day - days, 11, 0);
  }

  /// "All" sits in front of the pipeline stages, so index 0 means unfiltered
  /// and index n maps to `LeadStatus.values[n - 1]`.
  static const String _allLabel = 'All';

  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;
  String _query = '';

  LeadStatus? get _statusFilter =>
      _tabIndex == 0 ? null : LeadStatus.values[_tabIndex - 1];

  List<String> get _tabLabels => <String>[
    _allLabel,
    ...LeadStatus.values.map((LeadStatus status) => status.label),
  ];

  List<Lead> get _visibleLeads {
    final LeadStatus? status = _statusFilter;
    final List<Lead> inStage = status == null
        ? _allLeads
        : _allLeads.where((Lead lead) => lead.status == status).toList();

    final String needle = _query.trim().toLowerCase();
    if (needle.isEmpty) {
      return inStage;
    }
    return inStage.where((Lead lead) {
      return lead.name.toLowerCase().contains(needle) ||
          lead.mobile.contains(needle) ||
          (lead.requiredItems ?? '').toLowerCase().contains(needle);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Lead> leads = _visibleLeads;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            const AppGradientHeader(
              title: 'My Leads',
              eyebrow: 'LEAD MANAGEMENT',
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
              child: Column(
                children: <Widget>[
                  AppSegmentedTabs(
                    options: _tabLabels,
                    selectedIndex: _tabIndex,
                    onChanged: (int index) => setState(() => _tabIndex = index),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSearchField(
                    hint: 'Search by name, mobile or item…',
                    controller: _searchController,
                    onChanged: (String value) => setState(() => _query = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: leads.isEmpty
                  ? MyLeadsEmptyState(
                      status: _statusFilter,
                      hasQuery: _query.isNotEmpty,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.gutter,
                        right: AppSpacing.gutter,
                        bottom: AppSpacing.xl,
                      ),
                      itemCount: leads.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return MyLeadsCount(
                            count: leads.length,
                            total: _allLeads.length,
                          );
                        }
                        final Lead lead = leads[index - 1];
                        return MyLeadTile(
                          lead: lead,
                          onTap: () => context.push(AppRouteName.leadDetails),
                          onCall: () => PhoneDialer.call(context, lead.mobile),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: MyLeadsFab(
          onPressed: () => context.push(AppRouteName.leadNew),
        ),
      ),
    );
  }
}

/// "6 leads" / "Showing 2 of 6 leads" strip above the rows.
class MyLeadsCount extends StatelessWidget {
  const MyLeadsCount({super.key, required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final String label = count == total
        ? '$count lead${count == 1 ? '' : 's'}'
        : 'Showing $count of $total leads';

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

/// One lead row.
class MyLeadTile extends StatelessWidget {
  const MyLeadTile({super.key, required this.lead, this.onTap, this.onCall});

  final Lead lead;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final bool isDue = lead.isFollowUpDue();

    return AppSectionCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      accentBorder: isDue,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppInitialBubble(letter: lead.name, size: 42, isAccent: isDue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      lead.name,
                      style: context.type.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lead.requiredItems != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        lead.requiredItems!,
                        style: context.type.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        AppTag(
                          label: lead.status.label.toUpperCase(),
                          icon: Icons.flag_outlined,
                          isAccent: !lead.status.isClosed,
                        ),
                        if (lead.source != null)
                          AppTag(
                            label: lead.source!.label,
                            icon: Icons.campaign_outlined,
                            isAccent: false,
                          ),
                        if (isDue)
                          const AppTag(
                            label: 'FOLLOW UP DUE',
                            icon: Icons.alarm_on_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // The one action worth a tap of its own from a list: the whole
              // point of a lead row is ringing the customer back.
              IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.call_rounded, size: 19),
                color: AppColors.red,
                tooltip: 'Call ${lead.name}',
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing in this stage.
class MyLeadsEmptyState extends StatelessWidget {
  const MyLeadsEmptyState({
    super.key,
    required this.status,
    required this.hasQuery,
  });

  final LeadStatus? status;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final String stage = status?.label.toLowerCase() ?? 'assigned';
    final String title = hasQuery ? 'No matching leads' : 'No $stage leads';
    final String message = hasQuery
        ? 'Nothing here matches that search.'
        : 'Leads you capture or that are assigned to you will appear here.';

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
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.groups_outlined,
                size: 32,
                color: AppColors.red,
              ),
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

/// Red compose button, matching the follow-up list's.
class MyLeadsFab extends StatelessWidget {
  const MyLeadsFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.42),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
