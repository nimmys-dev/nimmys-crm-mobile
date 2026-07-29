import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

/// Rounded container that groups a block of related content.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = const EdgeInsets.only(bottom: AppSpacing.sm),
    this.accentBorder = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Draws a subtle red hairline instead of the neutral one.
  final bool accentBorder;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accentBorder ? palette.redBorder : palette.line,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow.withValues(
              alpha: context.isDarkMode ? 0.30 : 0.04,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section heading with an optional trailing "View All" affordance.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: context.type.sectionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(actionLabel!, style: context.type.link),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.red,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded square that holds an icon, tinted red or ink.
class AppIconChip extends StatelessWidget {
  const AppIconChip({
    super.key,
    required this.icon,
    this.size = 40,
    this.tone = AppIconChipTone.red,
  });

  final IconData icon;
  final double size;
  final AppIconChipTone tone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isRed = tone == AppIconChipTone.red;
    final bool isSolid = tone == AppIconChipTone.solid;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isSolid ? AppColors.actionGradient : null,
        color: isSolid
            ? null
            : isRed
            ? palette.redWash
            : palette.inkWash,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: isSolid
            ? AppColors.white
            : isRed
            ? AppColors.red
            : palette.ink,
      ),
    );
  }
}

enum AppIconChipTone { red, ink, solid }
