import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';

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
    final bool isRed = item.tone == StatTone.red;
    final Color tint = isRed ? AppColors.red : context.palette.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 116,
        decoration: BoxDecoration(
          color: isRed
              ? context.palette.redWashSoft
              : context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isRed
                ? context.palette.redBorder
                : context.palette.inkBorder,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 34,
              child: CustomPaint(painter: StatCardWavePainter(tint: tint)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: tint.withValues(alpha: 0.20)),
                    ),
                    child: Icon(item.icon, size: 16, color: tint),
                  ),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.palette.slate,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    item.value,
                    style: context.type.statValue.copyWith(
                      fontSize: 22,
                      color: tint,
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

/// Wide lead tile — arranged as a 2×2 grid under "MY LEADS".
class LeadStatCard extends StatelessWidget {
  const LeadStatCard({super.key, required this.item, this.onTap});

  final StatItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRed = item.tone == StatTone.red;
    final Color tint = isRed ? AppColors.red : context.palette.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isRed
              ? context.palette.redWashSoft
              : context.palette.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isRed
                ? context.palette.redBorder
                : context.palette.inkBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.icon, size: 17, color: tint),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: tint.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.type.statLabel,
            ),
            const SizedBox(height: 2),
            Text(
              item.value,
              style: context.type.statValue.copyWith(color: tint),
            ),
          ],
        ),
      ),
    );
  }
}

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
