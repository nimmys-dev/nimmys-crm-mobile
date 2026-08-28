import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Circular initials avatar. Sits on both dark headers and light lists.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.tone = AppAvatarTone.onDark,
    this.onTap,
  });

  final String initials;
  final double size;
  final AppAvatarTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool onDark = tone == AppAvatarTone.onDark;
    final bool isSolid = tone == AppAvatarTone.solid;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: isSolid ? AppColors.actionGradient : null,
          color: isSolid
              ? null
              : onDark
              ? AppColors.white.withValues(alpha: 0.16)
              : context.palette.redWash,
          shape: BoxShape.circle,
          border: Border.all(
            color: onDark
                ? AppColors.white.withValues(alpha: 0.55)
                : context.palette.redBorder,
            width: 1.4,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            color: onDark || isSolid ? AppColors.white : AppColors.red,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

enum AppAvatarTone { onDark, onLight, solid }

/// Coloured initial bubble used at the start of list rows.
class AppInitialBubble extends StatelessWidget {
  const AppInitialBubble({
    super.key,
    required this.letter,
    this.size = 34,
    this.isAccent = false,
  });

  final String letter;
  final double size;

  /// Accent bubbles are filled red; the rest use a neutral ink wash.
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isAccent ? context.palette.redWash : context.palette.inkWash,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAccent
              ? context.palette.redBorder
              : context.palette.inkBorder,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter.isEmpty ? '?' : letter.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: isAccent ? AppColors.red : context.palette.ink,
        ),
      ),
    );
  }
}
/// Small rounded status/meta tag.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.isAccent = true,
    this.tagColor, // <-- NEW
  });

  final String label;
  final IconData? icon;
  final bool isAccent;
  final Color? tagColor; // <-- NEW

  @override
  Widget build(BuildContext context) {
    Color fill;
    Color tint;

    if (tagColor != null) {
      // Use custom color with opacity for background
      fill = tagColor!.withOpacity(0.12);
      tint = tagColor!;
    } else {
      // Fallback to existing logic
      fill = isAccent ? context.palette.redWash : context.palette.inkWash;
      tint = isAccent ? AppColors.red : context.palette.ink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}