import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font families bundled with the app. Both are shipped as assets rather than
/// fetched at runtime — a national ID wallet has to render correctly on first
/// launch, offline, on a device that has never seen a Myanmar font.
abstract final class AppFonts {
  static const String myanmar = 'NotoSerifMyanmar';
  static const String latin = 'RobotoSlab';

  /// Every style declares the other family as a fallback so a Myanmar name
  /// inside an English screen (or an English document number inside a Myanmar
  /// sentence) never degrades to tofu boxes.
  static const List<String> fallback = [myanmar, latin];
}

/// Builds the locale-aware text theme.
///
/// Myanmar is the default language, so Burmese screens are set in Noto Serif
/// Myanmar, which stays readable at the stacked-diacritic sizes this script
/// needs. English screens are set in Roboto Slab. Numerals — OTP digits, PIN
/// dots, document numbers, dates — are always Roboto Slab regardless of
/// locale, because its tabular figures line up in a column and Burmese users
/// read Arabic numerals in official documents anyway.
abstract final class AppTypography {
  /// Myanmar glyphs carry above- and below-base marks, so they need more
  /// leading than Latin to avoid clipping between lines.
  static const double _myanmarLeading = 1.18;

  static TextTheme forLocale(Locale locale) {
    final bool isMyanmar = locale.languageCode == 'my';
    final String family = isMyanmar ? AppFonts.myanmar : AppFonts.latin;
    final double lead = isMyanmar ? _myanmarLeading : 1.0;

    TextStyle style(double size, double height, FontWeight weight,
            {Color color = AppColors.textPrimary, double spacing = 0}) =>
        TextStyle(
          fontFamily: family,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: size,
          height: (height / size) * lead,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
        );

    return TextTheme(
      displayLarge: style(30, 38, FontWeight.w700, spacing: -0.3),
      headlineLarge: style(25, 33, FontWeight.w700, spacing: -0.2),
      headlineMedium: style(21, 29, FontWeight.w600),
      titleLarge: style(18, 26, FontWeight.w600),
      titleMedium: style(16, 24, FontWeight.w600),
      titleSmall: style(14, 20, FontWeight.w600, color: AppColors.textSecondary),
      bodyLarge: style(16, 25, FontWeight.w400),
      bodyMedium: style(14, 22, FontWeight.w400, color: AppColors.textSecondary),
      bodySmall: style(13, 20, FontWeight.w400, color: AppColors.textSecondary),
      labelLarge: style(15, 20, FontWeight.w600),
      labelMedium: style(13, 18, FontWeight.w500, color: AppColors.textSecondary),
      labelSmall: style(11, 16, FontWeight.w500, color: AppColors.textTertiary),
    );
  }

  /// Numeric / monospaced-feel style for OTP boxes, PIN entry, key fingerprints
  /// and document numbers. Never locale-switched.
  static TextStyle numeric({
    double size = 22,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double spacing = 0.5,
  }) =>
      TextStyle(
        fontFamily: AppFonts.latin,
        fontFamilyFallback: AppFonts.fallback,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Base-64 keys and transaction ids: same family, tighter and dimmer.
  static TextStyle mono({double size = 12, Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontFamily: AppFonts.latin,
        fontSize: size,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.2,
      );
}
