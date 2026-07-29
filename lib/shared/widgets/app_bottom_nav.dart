import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';

/// Data holder for one destination in [AppBottomNav].
class AppNavItem {
  const AppNavItem({required this.label, required this.icon, this.activeIcon});

  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

/// Bottom navigation bar with an optional raised centre action.
///
/// Purely presentational — the host screen decides what each tap does.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.centerAction,
    this.onCenterTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// When provided, a floating red button is injected in the middle.
  final AppNavItem? centerAction;
  final VoidCallback? onCenterTap;

  @override
  Widget build(BuildContext context) {
    final bool hasCenter = centerAction != null;
    final int splitAt = (items.length / 2).ceil();

    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(top: BorderSide(color: context.palette.line)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: <Widget>[
              for (int index = 0; index < items.length; index++) ...<Widget>[
                if (hasCenter && index == splitAt)
                  AppBottomNavCenterButton(
                    item: centerAction!,
                    onTap: onCenterTap,
                  ),
                Expanded(
                  child: AppBottomNavTab(
                    item: items[index],
                    isSelected: index == currentIndex,
                    onTap: onTap == null ? null : () => onTap!(index),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single destination tab.
class AppBottomNavTab extends StatelessWidget {
  const AppBottomNavTab({
    super.key,
    required this.item,
    required this.isSelected,
    this.onTap,
  });

  final AppNavItem item;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = isSelected ? AppColors.red : context.palette.muted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 20 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Icon(
            isSelected ? (item.activeIcon ?? item.icon) : item.icon,
            size: 21,
            color: tint,
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: tint,
                height: 1.1,
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

/// The raised red action sitting in the middle of the nav bar.
class AppBottomNavCenterButton extends StatelessWidget {
  const AppBottomNavCenterButton({super.key, required this.item, this.onTap});

  final AppNavItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Transform.translate(
            offset: const Offset(0, -14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.actionGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 4),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.red.withValues(alpha: 0.40),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onTap,
                      customBorder: const CircleBorder(),
                      child: Icon(item.icon, size: 24, color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
