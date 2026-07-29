import 'package:flutter/material.dart';

import '../preferences/app_preferences.dart';

/// Holds the active [ThemeMode] and persists every change.
///
/// Exposed to the tree by [ThemeScope]; read it with
/// `ThemeScope.of(context)`.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode? initialMode})
    : _themeMode =
          initialMode ??
          (AppPreferences.isReady
              ? AppPreferences.instance.themeMode
              : ThemeMode.system);

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  /// Resolves [ThemeMode.system] against the current platform brightness.
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
    if (AppPreferences.isReady) {
      await AppPreferences.instance.setThemeMode(mode);
    }
  }

  /// Flips between explicit light and dark, resolving `system` first.
  Future<void> toggle(BuildContext context) {
    return setThemeMode(isDark(context) ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Makes the [ThemeController] available to descendants.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final ThemeScope? scope = context
        .dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'No ThemeScope found in the widget tree.');
    return scope!.notifier!;
  }

  /// Returns null instead of asserting — for widgets that may be previewed
  /// outside the app shell.
  static ThemeController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;
  }
}
