import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';

/// Round sun/moon switch for the dark gradient headers.
///
/// Silently renders nothing when no [ThemeScope] is present, so screens stay
/// previewable in isolation.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeController? controller = ThemeScope.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final bool isDark = controller.isDark(context);

    return Semantics(
      button: true,
      label: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      child: Material(
        color: AppColors.white.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => controller.toggle(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.6, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                key: ValueKey<bool>(isDark),
                size: size * 0.48,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-way System / Light / Dark selector for a settings surface.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  static const List<_ThemeModeOption> _options = <_ThemeModeOption>[
    _ThemeModeOption(
      mode: ThemeMode.system,
      label: 'System',
      icon: Icons.brightness_auto_rounded,
    ),
    _ThemeModeOption(
      mode: ThemeMode.light,
      label: 'Light',
      icon: Icons.light_mode_rounded,
    ),
    _ThemeModeOption(
      mode: ThemeMode.dark,
      label: 'Dark',
      icon: Icons.dark_mode_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeController? controller = ThemeScope.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.inkWash,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: <Widget>[
          for (final _ThemeModeOption option in _options)
            Expanded(
              child: ThemeModeChip(
                label: option.label,
                icon: option.icon,
                isSelected: controller.themeMode == option.mode,
                onTap: () => controller.setThemeMode(option.mode),
              ),
            ),
        ],
      ),
    );
  }
}

/// Data holder for a [ThemeModeSelector] entry.
class _ThemeModeOption {
  const _ThemeModeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
}

/// One option inside [ThemeModeSelector].
class ThemeModeChip extends StatelessWidget {
  const ThemeModeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.actionGradient : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.white : context.palette.slate,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.white : context.palette.slate,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
