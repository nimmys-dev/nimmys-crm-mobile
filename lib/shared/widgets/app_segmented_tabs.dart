import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Horizontal single-choice selector used for Task Type / Frequency rows.
///
/// Scrolls horizontally so five options stay legible on narrow devices.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.options,
    required this.selectedIndex,
    this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.inkWash,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int index = 0; index < options.length; index++)
              AppSegmentedTab(
                label: options[index],
                isSelected: index == selectedIndex,
                onTap: onChanged == null ? null : () => onChanged!(index),
              ),
          ],
        ),
      ),
    );
  }
}

/// One option inside [AppSegmentedTabs].
class AppSegmentedTab extends StatelessWidget {
  const AppSegmentedTab({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.actionGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.white : context.palette.slate,
          ),
        ),
      ),
    );
  }
}

/// Underlined tab row used on the Staff Creation screen.
class AppUnderlineTabs extends StatelessWidget {
  const AppUnderlineTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onChanged,
  });

  final List<AppUnderlineTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int index = 0; index < tabs.length; index++)
          Expanded(
            child: AppUnderlineTab(
              item: tabs[index],
              isSelected: index == selectedIndex,
              onTap: onChanged == null ? null : () => onChanged!(index),
            ),
          ),
      ],
    );
  }
}

/// Data holder for a single [AppUnderlineTabs] entry.
class AppUnderlineTabItem {
  const AppUnderlineTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// One tab inside [AppUnderlineTabs].
class AppUnderlineTab extends StatelessWidget {
  const AppUnderlineTab({
    super.key,
    required this.item,
    required this.isSelected,
    this.onTap,
  });

  final AppUnderlineTabItem item;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = isSelected ? AppColors.red : context.palette.muted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(item.icon, size: 17, color: tint),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: tint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.red : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled on/off row with a brand-red switch.
class AppToggleRow extends StatelessWidget {
  const AppToggleRow({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: value ? context.palette.redWashSoft : context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: value ? context.palette.redBorder : context.palette.line,
        ),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 19,
              color: value ? AppColors.red : context.palette.muted,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.palette.ink,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.palette.slate,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.white,
            activeTrackColor: AppColors.red,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: context.palette.inkBorder,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
