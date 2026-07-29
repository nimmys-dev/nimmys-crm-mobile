import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Light and dark [ThemeData] for NIMMYS CRM.
///
/// Both themes carry an [AppPalette] and an [AppTypography] extension; widgets
/// read them through `context.palette` and `context.type` so a single
/// `themeMode` switch restyles the whole app.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppPalette.light);

  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.red,
      onPrimary: AppColors.white,
      primaryContainer: palette.redWash,
      onPrimaryContainer: isDark ? AppColors.white : AppColors.redInk,
      secondary: palette.ink,
      onSecondary: palette.surface,
      secondaryContainer: palette.inkWash,
      onSecondaryContainer: palette.ink,
      error: isDark ? AppColors.redBright : AppColors.redDeep,
      onError: AppColors.white,
      surface: palette.surface,
      onSurface: palette.ink,
      surfaceContainerHighest: palette.inkWash,
      onSurfaceVariant: palette.slate,
      outline: palette.line,
      outlineVariant: palette.inkBorder,
      shadow: palette.shadow,
      scrim: AppColors.black,
      inverseSurface: isDark ? AppColors.white : AppColors.black,
      onInverseSurface: isDark ? AppColors.black : AppColors.white,
      inversePrimary: AppColors.redBright,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.surface,
      splashColor: palette.redWash,
      highlightColor: palette.redWashSoft,
      dividerColor: palette.line,
      textTheme: GoogleFonts.montserratTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ).apply(bodyColor: palette.ink, displayColor: palette.ink),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.red,
        selectionColor: palette.redBorder,
        selectionHandleColor: AppColors.red,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.red,
        linearTrackColor: palette.inkWash,
      ),
      // Cupertino transitions on Apple platforms keep the edge-swipe-back
      // gesture working, which App Store review expects alongside the
      // on-screen back button.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[
        palette,
        AppTypography.from(palette),
      ],
    );
  }
}

/// Shorthand access to the brand palette and type scale.
extension AppThemeContext on BuildContext {
  /// Surface colours for the active theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// Montserrat type scale for the active theme.
  AppTypography get type =>
      Theme.of(this).extension<AppTypography>() ??
      AppTypography.from(AppPalette.light);

  /// Whether the app is currently rendering in dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
