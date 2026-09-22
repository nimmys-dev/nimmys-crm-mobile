import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';

/// Visual weight of a stat tile. Kept to red / ink so the dashboard stays on
/// brand while still separating urgent counts from routine ones.
enum StatTone { red, ink }

/// Immutable description of one dashboard metric.
class StatItem {
  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = StatTone.red,
    this.route,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatTone tone;

  /// Named route this tile opens. Null leaves the tile inert, which is what a
  /// counter with no screen behind it should be — a tap that does nothing reads
  /// as a broken button.
  final String? route;
}

/// Compact duty tile — four of these sit side by side under "MY DUTIES".
class DutyStatCard extends StatelessWidget {
  const DutyStatCard({super.key, required this.item, this.onTap});

  final StatItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final _DashboardCardScheme scheme = _DashboardCardScheme.forItem(item);

    return _AttentionTwinkle(
      // enabled: _shouldTwinkle(item),
      enabled: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 142,
          decoration: BoxDecoration(
            color: scheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(1, 10, 1, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.icon, size: 18, color: scheme.tint),
                    const SizedBox(height: 5),
                    Text(
                      item.value,
                      style: context.type.statValue.copyWith(
                        fontSize: 13,
                        color: context.palette.ink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _shortDutyLabel(item.label),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: scheme.tint,
                        height: 1.12,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ArrowBadge(color: scheme.tint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide lead tile — arranged as a 2×2 grid under "MY LEADS".
class LeadStatCard extends StatelessWidget {
  const LeadStatCard({super.key, required this.item, this.onTap});

  final StatItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final _DashboardCardScheme scheme = _DashboardCardScheme.forItem(item);

    return _AttentionTwinkle(
      enabled: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: scheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(item.icon, size: 18, color: scheme.tint),
              const SizedBox(height: 5),
              Text(
                item.value,
                style: context.type.statValue.copyWith(
                  fontSize: 13,
                  color: context.palette.ink,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _shortLeadLabel(item.label),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: scheme.tint,
                  height: 1.12,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: _ArrowBadge(color: scheme.tint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _shouldTwinkle(StatItem item) {
  final bool isOverdue = item.label.toLowerCase().contains('overdue');
  return isOverdue && (int.tryParse(item.value) ?? 0) > 0;
}

/// A gentle repeating fade used to draw attention to actionable overdue work.
class _AttentionTwinkle extends StatefulWidget {
  const _AttentionTwinkle({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_AttentionTwinkle> createState() => _AttentionTwinkleState();
}

class _AttentionTwinkleState extends State<_AttentionTwinkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AttentionTwinkle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled == oldWidget.enabled) return;
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.45).animate(_controller),
      child: widget.child,
    );
  }
}

class _ArrowBadge extends StatelessWidget {
  const _ArrowBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 29,
    height: 29,
    decoration: const BoxDecoration(
      color: AppColors.white,
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.arrow_forward_rounded, size: 18, color: color),
  );
}

class _DashboardCardScheme {
  const _DashboardCardScheme(this.background, this.tint);
  final Color background;
  final Color tint;

  factory _DashboardCardScheme.forItem(StatItem item) {
    final String label = item.label.toLowerCase();
    if (label.contains('overdue')) {
      return const _DashboardCardScheme(Color(0xFFFFE8EC), AppColors.red);
    }
    if (label.contains('today')) {
      return const _DashboardCardScheme(Color(0xFFE4F4FF), Color(0xFF1297E8));
    }
    if (label.contains('upcoming')) {
      return const _DashboardCardScheme(Color(0xFFF0E8FF), Color(0xFF8B27F0));
    }
    if (label.contains('approval pending')) {
      return const _DashboardCardScheme(Color(0xFFFFF5D9), Color(0xFFFFAA00));
    }
    if (label.contains('sending')) {
      return const _DashboardCardScheme(Color(0xFFDFFBEA), Color(0xFF08AB4B));
    }
    if (label.contains('unattended')) {
      return const _DashboardCardScheme(Color(0xFFFFF1DD), Color(0xFFB87300));
    }
    return const _DashboardCardScheme(Color(0xFFE4F4FF), Color(0xFF1297E8));
  }
}

String _shortDutyLabel(String label) => label
    .replaceAll("Today's My Duty", "Today's\nDuty")
    .replaceAll("Today's All Duty", "Today's\nDuty")
    .replaceAll('Overdue Duty', 'Overdue\nDuty')
    .replaceAll('Upcoming Duty', 'Upcoming\nDuty')
    .replaceAll('Approval Pending', 'Approval\nPending')
    .replaceAll('Sending Approval', 'Sending\nApproval');

String _shortLeadLabel(String label) => label
    .replaceAll('Unattended Leads', 'Unattended\nLeads')
    .replaceAll('Overdue Follow Up', 'Overdue\nFollow Up')
    .replaceAll("Today's Follow Up", "Today's\nFollow Up")
    .replaceAll('Upcoming Follow Up', 'Upcoming\nFollow Up');

/// Soft wave printed along the bottom of a [DutyStatCard].
class StatCardWavePainter extends CustomPainter {
  const StatCardWavePainter({required this.tint});

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = tint.withValues(alpha: 0.10);
    final Path path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.28,
        0,
        size.width * 0.55,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.68,
        size.width,
        size.height * 0.22,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StatCardWavePainter oldDelegate) =>
      oldDelegate.tint != tint;
}
