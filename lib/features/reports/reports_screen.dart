import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nimmys_crm/shared/widgets/app_buttons.dart';
import 'package:nimmys_crm/shared/widgets/app_gradient_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/app_segmented_tabs.dart';
import '../dashboard/widgets/dashboard_panels.dart';
import '../dashboard/widgets/stat_cards.dart';

/// The period a report covers.
enum ReportPeriod {
  week('This Week'),
  month('This Month'),
  quarter('This Quarter');

  const ReportPeriod(this.label);

  final String label;

  static List<String> get labels =>
      ReportPeriod.values.map((ReportPeriod p) => p.label).toList();
}

/// Reports — team performance behind the dashboard's "Report" card.
///
/// The destination for the Reports nav item, the Report section's "View All"
/// and the report card itself, all of which admin and manager see; the route
/// carries the same `viewDashboardFull` permission that gates them.
///
/// DATA — sample figures. This project has no reporting endpoint (`ApiUrls`
/// covers auth, profile and staff only) and the dashboard counters are
/// hard-coded for the same reason. The widgets take plain values, so wiring a
/// cubit in later touches only [_figuresFor].
class ReportsScreen extends StatefulWidget {
  final bool isAppHeaderRequired;
  const ReportsScreen({super.key, required this.isAppHeaderRequired});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _periodIndex = 1;

  ReportPeriod get _period => ReportPeriod.values[_periodIndex];

  /// Headline counters for the selected period.
  List<StatItem> _figuresFor(ReportPeriod period) {
    final (
      String leads,
      String won,
      String duties,
      String followUps,
    ) = switch (period) {
      ReportPeriod.week => ('24', '6', '31', '18'),
      ReportPeriod.month => ('96', '27', '128', '74'),
      ReportPeriod.quarter => ('284', '81', '392', '221'),
    };

    return <StatItem>[
      StatItem(
        label: 'Leads Captured',
        value: leads,
        icon: Icons.groups_outlined,
      ),
      StatItem(
        label: 'Deals Won',
        value: won,
        icon: Icons.emoji_events_outlined,
        tone: StatTone.ink,
      ),
      StatItem(
        label: 'Duties Closed',
        value: duties,
        icon: Icons.fact_check_outlined,
        tone: StatTone.ink,
      ),
      StatItem(
        label: 'Follow Ups',
        value: followUps,
        icon: Icons.alarm_on_rounded,
      ),
    ];
  }

  /// Per-person contribution for the selected period, highest first.
  List<ReportRow> _leaderboardFor(ReportPeriod period) {
    final int scale = switch (period) {
      ReportPeriod.week => 1,
      ReportPeriod.month => 4,
      ReportPeriod.quarter => 12,
    };
    final List<ReportRow> rows = <ReportRow>[
      ReportRow(name: 'Abin Babu', leads: 9 * scale, won: 3 * scale),
      ReportRow(name: 'Sijo', leads: 7 * scale, won: 2 * scale),
      ReportRow(name: 'Mathew Thomas', leads: 5 * scale, won: 1 * scale),
      ReportRow(name: 'Thomas John', leads: 3 * scale, won: 0),
    ]..sort((ReportRow a, ReportRow b) => b.leads.compareTo(a.leads));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final List<StatItem> figures = _figuresFor(_period);
    final List<ReportRow> leaderboard = _leaderboardFor(_period);
    final int topLeads = leaderboard.isEmpty ? 0 : leaderboard.first.leads;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.palette.canvas,
        body: Column(
          children: <Widget>[
            Visibility(
              visible: widget.isAppHeaderRequired,
              child: const AppGradientHeader(
                title: 'My Reports',
                eyebrow: 'REPORTS',
                leading: AppBackButton(),
                actions: <Widget>[AppAvatar(initials: 'AB')],
              ),
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
                  AppSegmentedTabs(
                    options: ReportPeriod.labels,
                    selectedIndex: _periodIndex,
                    onChanged: (int index) =>
                        setState(() => _periodIndex = index),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSectionCard(
                    child: Column(
                      children: <Widget>[
                        AppSectionHeader(title: _period.label),
                        const SizedBox(height: AppSpacing.sm),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: figures.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: AppSpacing.xs,
                                crossAxisSpacing: AppSpacing.xs,
                                mainAxisExtent: 134,
                              ),
                          itemBuilder: (BuildContext context, int index) =>
                              LeadStatCard(item: figures[index]),
                        ),
                      ],
                    ),
                  ),
                  AppSectionCard(
                    child: DashboardTotalsCard(
                      yourLeads: figures.first.value,
                      totalLeads: leaderboard
                          .fold<int>(
                            0,
                            (int sum, ReportRow row) => sum + row.leads,
                          )
                          .toString(),
                    ),
                  ),
                  AppSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const AppSectionHeader(title: 'By Team Member'),
                        const SizedBox(height: AppSpacing.sm),
                        for (final ReportRow row in leaderboard)
                          ReportLeaderboardRow(row: row, topLeads: topLeads),
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

/// One person's contribution in the period.
class ReportRow {
  const ReportRow({required this.name, required this.leads, required this.won});

  final String name;
  final int leads;
  final int won;
}

/// A name, a proportional bar and the two numbers behind it.
///
/// A bar rather than a chart package: the comparison here is one value against
/// the best one, which a width already says.
class ReportLeaderboardRow extends StatelessWidget {
  const ReportLeaderboardRow({
    super.key,
    required this.row,
    required this.topLeads,
  });

  final ReportRow row;
  final int topLeads;

  @override
  Widget build(BuildContext context) {
    final double fraction = topLeads == 0 ? 0 : row.leads / topLeads;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppInitialBubble(letter: row.name, size: 30),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  row.name,
                  style: context.type.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${row.leads} leads · ${row.won} won',
                style: context.type.caption,
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: context.palette.inkWash,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}
