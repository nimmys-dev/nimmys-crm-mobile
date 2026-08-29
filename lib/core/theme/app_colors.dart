import 'package:flutter/material.dart';

/// Fixed brand anchors for NIMMYS CRM — red, black and white.
///
/// These never change between light and dark mode. Anything that *does* change
/// with the surface lives on [AppPalette] instead.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------- Brand red
  static const Color red = Color(0xFFE62B1E);
  static const Color redBright = Color(0xFFFF4032);
  static const Color redDeep = Color(0xFFB3140A);
  static const Color redInk = Color(0xFF7A0C05);

  /// The accent, under the name used by code that runs outside the widget
  /// tree — notification dialogs, platform surfaces — and so cannot reach the
  /// theme to ask for `colorScheme.primary`.
  static const Color primaryColor = red;

  // -------------------------------------------------------------- Black/white
  static const Color black = Color(0xFF0A0A0C);
  static const Color blackSoft = Color(0xFF15161A);
  static const Color white = Color(0xFFFFFFFF);

  // -------------------------------------------------------------- Neutral tones
  /// Light grey used for background fills in cards (e.g., totals box).
  static const Color lightGrey = Color(0xFFF0F0F0);

  /// Static muted grey – for fallback or non‑themed use.
  /// For themed text colours, prefer [AppPalette.muted].
  static const Color muted = Color(0xFF8C93A1);
  // Status colours (added)
  static const Color green = Color(0xFF2E7D32);
  static const Color blue = Color(0xFF1565C0);
  static const Color orange = Color(0xFFE65100);
  static const Color purple = Color(0xFF6A1B9A);
  static const Color darkGreen = Color.fromARGB(255, 3, 171, 23);

  // ---------------------------------------------------------------- Gradients
  /// Primary call-to-action fill. Identical in both themes.
  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[redBright, red, redDeep],
  );

  /// Curved screen header. Reads as brand on light and dark alike.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[black, Color(0xFF2A0F0C), redDeep],
  );

  /// Splash / login stage backdrop.
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[black, Color(0xFF120708), Color(0xFF1C0806)],
  );
}

/// Surface-dependent colours, resolved from the active [ThemeData].
///
/// Read it with `context.palette` — see `app_theme.dart`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.slate,
    required this.muted,
    required this.faint,
    required this.inkWash,
    required this.inkBorder,
    required this.redWash,
    required this.redWashSoft,
    required this.redBorder,
    required this.shadow,
    required this.inkGradient,
  });

  /// Page background behind the cards.
  final Color canvas;

  /// Card / sheet background.
  final Color surface;

  /// Inset fills such as text fields and list tiles.
  final Color surfaceAlt;

  /// Hairline borders and dividers.
  final Color line;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color slate;

  /// Tertiary text and inactive icons.
  final Color muted;

  /// Placeholder text and disabled glyphs.
  final Color faint;

  /// Neutral tinted fill for icon chips.
  final Color inkWash;

  /// Border paired with [inkWash].
  final Color inkBorder;

  /// Red tinted fill for accent chips.
  final Color redWash;

  /// The softest red tint, used for whole-card washes.
  final Color redWashSoft;

  /// Border paired with the red washes.
  final Color redBorder;

  /// Drop-shadow colour for elevated cards.
  final Color shadow;

  /// Dark panel fill (the totals card).
  final LinearGradient inkGradient;

  static const AppPalette light = AppPalette(
    canvas: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFAFAFB),
    line: Color(0xFFE8EAEF),
    ink: Color(0xFF1A1C22),
    slate: Color(0xFF5C6270),
    muted: Color(0xFF8C93A1),
    faint: Color(0xFFB6BCC7),
    inkWash: Color(0xFFF0F1F4),
    inkBorder: Color(0xFFDDE0E7),
    redWash: Color(0xFFFDECEA),
    redWashSoft: Color(0xFFFFF5F3),
    redBorder: Color(0xFFF7C9C4),
    shadow: Color(0xFF0A0A0C),
    inkGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[Color(0xFF2E3138), AppColors.black],
    ),
  );

  static const AppPalette dark = AppPalette(
    canvas: Color(0xFF0E0F12),
    surface: Color(0xFF17191F),
    surfaceAlt: Color(0xFF1E2128),
    line: Color(0xFF282C35),
    ink: Color(0xFFF1F3F7),
    slate: Color(0xFFA9AFBC),
    muted: Color(0xFF7E8698),
    faint: Color(0xFF5D6475),
    inkWash: Color(0xFF232730),
    inkBorder: Color(0xFF313641),
    redWash: Color(0xFF331612),
    redWashSoft: Color(0xFF25120F),
    redBorder: Color(0xFF5A241D),
    shadow: Color(0xFF000000),
    inkGradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[Color(0xFF23262E), Color(0xFF101216)],
    ),
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? line,
    Color? ink,
    Color? slate,
    Color? muted,
    Color? faint,
    Color? inkWash,
    Color? inkBorder,
    Color? redWash,
    Color? redWashSoft,
    Color? redBorder,
    Color? shadow,
    LinearGradient? inkGradient,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      slate: slate ?? this.slate,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      inkWash: inkWash ?? this.inkWash,
      inkBorder: inkBorder ?? this.inkBorder,
      redWash: redWash ?? this.redWash,
      redWashSoft: redWashSoft ?? this.redWashSoft,
      redBorder: redBorder ?? this.redBorder,
      shadow: shadow ?? this.shadow,
      inkGradient: inkGradient ?? this.inkGradient,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      inkWash: Color.lerp(inkWash, other.inkWash, t)!,
      inkBorder: Color.lerp(inkBorder, other.inkBorder, t)!,
      redWash: Color.lerp(redWash, other.redWash, t)!,
      redWashSoft: Color.lerp(redWashSoft, other.redWashSoft, t)!,
      redBorder: Color.lerp(redBorder, other.redBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      inkGradient:
          LinearGradient.lerp(inkGradient, other.inkGradient, t) ?? inkGradient,
    );
  }
}
