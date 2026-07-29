import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_dimens.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_gradient_header.dart';
import '../../shared/widgets/app_section_card.dart';
import 'widgets/lead_detail_widgets.dart';

/// Lead Details — customer profile, requested items and the call history.
class LeadDetailsScreen extends StatefulWidget {
  const LeadDetailsScreen({super.key});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  static const List<String> _items = <String>[
    'Sigma 85mm 1:4 Lens',
    'Canon Camera 85mm',
  ];

  static const List<CallLogEntry> _calls = <CallLogEntry>[
    CallLogEntry(
      outcome: 'Answered',
      remarks: 'Waiting for the product. Will confirm once stock arrives.',
      calledBy: 'Ajith Canon',
      calledAt: '01/05/2024 · 10:30 AM',
    ),
    CallLogEntry(
      outcome: 'Not Reachable',
      remarks: 'Phone switched off. Retry in the evening.',
      calledBy: 'Abin Babu',
      calledAt: '28/04/2024 · 04:15 PM',
      isAnswered: false,
    ),
  ];

  int _navIndex = 1;

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
              title: 'Lead Details',
              eyebrow: 'LEAD #10428',
              leading: AppBackButton(),
              actions: <Widget>[AppAvatar(initials: 'AB')],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.gutter,
                  right: AppSpacing.gutter,
                  top: AppSpacing.md,
                  bottom: AppSpacing.xl,
                ),
                children: <Widget>[
                  const LeadSummaryCard(
                    name: 'Sojan',
                    mobile: '9961210000',
                    status: 'Follow up',
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        LeadSectionTitle(
                          title: 'Customer Details',
                          icon: Icons.person_outline_rounded,
                          action: AppPillButton(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const LeadDetailsGrid(),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        LeadSectionTitle(
                          title: 'Item Details',
                          icon: Icons.sell_outlined,
                          action: AppPillButton(
                            label: 'Edit',
                            icon: Icons.edit_outlined,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (int index = 0; index < _items.length; index++)
                          LeadItemRow(
                            name: _items[index],
                            isLast: index == _items.length - 1,
                          ),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        LeadSectionTitle(
                          title: 'Call Details',
                          icon: Icons.call_outlined,
                          action: AppPillButton(
                            label: 'Add Call',
                            icon: Icons.add_rounded,
                            tone: AppIconChipStyle.filled,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (int index = 0; index < _calls.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == _calls.length - 1
                                  ? 0
                                  : AppSpacing.xs,
                            ),
                            child: CallLogCard(entry: _calls[index]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          items: const <AppNavItem>[
            AppNavItem(
              label: 'Dashboard',
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
            ),
            AppNavItem(
              label: 'Leads',
              icon: Icons.groups_outlined,
              activeIcon: Icons.groups_rounded,
            ),
            AppNavItem(
              label: 'Calendar',
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
            ),
            AppNavItem(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
            ),
          ],
          currentIndex: _navIndex,
          onTap: (int index) => setState(() => _navIndex = index),
          centerAction: const AppNavItem(label: 'Add', icon: Icons.add_rounded),
        ),
      ),
    );
  }
}

/// Identity strip at the top of the lead: avatar, name, status and actions.
class LeadSummaryCard extends StatelessWidget {
  const LeadSummaryCard({
    super.key,
    required this.name,
    required this.mobile,
    required this.status,
  });

  final String name;
  final String mobile;
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      accentBorder: true,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              AppAvatar(
                initials: name.substring(0, 1),
                size: 48,
                tone: AppAvatarTone.solid,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      name,
                      style: context.type.pageHeading.copyWith(fontSize: 19),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.call_outlined,
                          size: 13,
                          color: context.palette.muted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            mobile,
                            style: context.type.bodyMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppTag(label: status, icon: Icons.flag_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const LeadQuickActions(),
        ],
      ),
    );
  }
}

/// Two-column grid of the lead's core attributes.
class LeadDetailsGrid extends StatelessWidget {
  const LeadDetailsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LeadDetailTile(
                label: 'Name',
                value: 'Sojan',
                icon: Icons.person_outline_rounded,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Mobile No',
                value: '9961210000',
                icon: Icons.call_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: LeadDetailTile(
                label: 'Created By',
                value: 'Ajith Canon',
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Date & Time',
                value: '01/05/2024',
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: LeadDetailTile(
                label: 'Assigned To',
                value: 'Ajith Canon',
                icon: Icons.assignment_ind_outlined,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: LeadDetailTile(
                label: 'Next Follow Up',
                value: '05/10/2024',
                icon: Icons.event_rounded,
                isAccent: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
