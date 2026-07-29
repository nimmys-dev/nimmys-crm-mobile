import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Montserrat type scale for NIMMYS CRM, resolved per theme brightness.
///
/// Read it with `context.type` — see `app_theme.dart`. Styles already carry
/// their colour, so widgets rarely need to override anything.
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.splashWordmark,
    required this.splashTagline,
    required this.screenTitle,
    required this.headerEyebrow,
    required this.pageHeading,
    required this.sectionTitle,
    required this.cardTitle,
    required this.body,
    required this.bodyMuted,
    required this.caption,
    required this.label,
    required this.hint,
    required this.input,
    required this.statValue,
    required this.statLabel,
    required this.button,
    required this.link,
    required this.tableHeader,
  });

  final TextStyle splashWordmark;
  final TextStyle splashTagline;
  final TextStyle screenTitle;
  final TextStyle headerEyebrow;
  final TextStyle pageHeading;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle bodyMuted;
  final TextStyle caption;
  final TextStyle label;
  final TextStyle hint;
  final TextStyle input;
  final TextStyle statValue;
  final TextStyle statLabel;
  final TextStyle button;
  final TextStyle link;
  final TextStyle tableHeader;

  /// Builds the scale against a palette so text colours follow the theme.
  factory AppTypography.from(AppPalette palette) {
    return AppTypography(
      splashWordmark: GoogleFonts.montserrat(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: -1.0,
        height: 1.0,
      ),
      splashTagline: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFB6BCC7),
        letterSpacing: 4.0,
      ),
      // Header styles always sit on the dark gradient, so they stay light in
      // both themes.
      screenTitle: GoogleFonts.montserrat(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.2,
      ),
      headerEyebrow: GoogleFonts.montserrat(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xCCFFFFFF),
        letterSpacing: 1.6,
      ),
      pageHeading: GoogleFonts.montserrat(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: palette.ink,
        letterSpacing: -0.4,
      ),
      sectionTitle: GoogleFonts.montserrat(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: palette.ink,
        letterSpacing: 1.1,
      ),
      cardTitle: GoogleFonts.montserrat(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: palette.ink,
        letterSpacing: -0.1,
      ),
      body: GoogleFonts.montserrat(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: palette.ink,
        height: 1.4,
      ),
      bodyMuted: GoogleFonts.montserrat(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: palette.slate,
        height: 1.4,
      ),
      caption: GoogleFonts.montserrat(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: palette.muted,
        height: 1.3,
      ),
      label: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: palette.ink,
        letterSpacing: 0.1,
      ),
      hint: GoogleFonts.montserrat(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: palette.faint,
      ),
      input: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: palette.ink,
      ),
      statValue: GoogleFonts.montserrat(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: palette.ink,
        letterSpacing: -0.8,
        height: 1.0,
      ),
      statLabel: GoogleFonts.montserrat(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: palette.slate,
        height: 1.25,
      ),
      button: GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.3,
      ),
      link: GoogleFonts.montserrat(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.red,
      ),
      tableHeader: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: 0.6,
      ),
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? splashWordmark,
    TextStyle? splashTagline,
    TextStyle? screenTitle,
    TextStyle? headerEyebrow,
    TextStyle? pageHeading,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? body,
    TextStyle? bodyMuted,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? hint,
    TextStyle? input,
    TextStyle? statValue,
    TextStyle? statLabel,
    TextStyle? button,
    TextStyle? link,
    TextStyle? tableHeader,
  }) {
    return AppTypography(
      splashWordmark: splashWordmark ?? this.splashWordmark,
      splashTagline: splashTagline ?? this.splashTagline,
      screenTitle: screenTitle ?? this.screenTitle,
      headerEyebrow: headerEyebrow ?? this.headerEyebrow,
      pageHeading: pageHeading ?? this.pageHeading,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      body: body ?? this.body,
      bodyMuted: bodyMuted ?? this.bodyMuted,
      caption: caption ?? this.caption,
      label: label ?? this.label,
      hint: hint ?? this.hint,
      input: input ?? this.input,
      statValue: statValue ?? this.statValue,
      statLabel: statLabel ?? this.statLabel,
      button: button ?? this.button,
      link: link ?? this.link,
      tableHeader: tableHeader ?? this.tableHeader,
    );
  }

  @override
  AppTypography lerp(covariant ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      splashWordmark: TextStyle.lerp(splashWordmark, other.splashWordmark, t)!,
      splashTagline: TextStyle.lerp(splashTagline, other.splashTagline, t)!,
      screenTitle: TextStyle.lerp(screenTitle, other.screenTitle, t)!,
      headerEyebrow: TextStyle.lerp(headerEyebrow, other.headerEyebrow, t)!,
      pageHeading: TextStyle.lerp(pageHeading, other.pageHeading, t)!,
      sectionTitle: TextStyle.lerp(sectionTitle, other.sectionTitle, t)!,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyMuted: TextStyle.lerp(bodyMuted, other.bodyMuted, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      hint: TextStyle.lerp(hint, other.hint, t)!,
      input: TextStyle.lerp(input, other.input, t)!,
      statValue: TextStyle.lerp(statValue, other.statValue, t)!,
      statLabel: TextStyle.lerp(statLabel, other.statLabel, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      link: TextStyle.lerp(link, other.link, t)!,
      tableHeader: TextStyle.lerp(tableHeader, other.tableHeader, t)!,
    );
  }
}
