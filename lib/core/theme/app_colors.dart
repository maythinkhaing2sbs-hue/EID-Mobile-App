import 'package:flutter/material.dart';

/// Single source of truth for colour in the eID wallet.
///
/// The five brand values come straight from the design system; everything
/// below them is a supporting neutral derived to keep contrast at or above
/// WCAG AA on the two approved backgrounds (white and [surfaceMuted]).
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF266DD3);
  static const Color primaryDark = Color(0xFF1B4F9C);
  static const Color primaryPressed = Color(0xFF17417F);
  static const Color secondary = Color(0xFFE3F2FD);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningSurface = Color(0xFFFFF8E1);
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerSurface = Color(0xFFFDECEC);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F5F5);
  static const Color surfaceSunken = Color(0xFFEDF1F7);

  // Ink
  static const Color textPrimary = Color(0xFF16202E);
  static const Color textSecondary = Color(0xFF5B6577);
  static const Color textTertiary = Color(0xFF8A93A3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Lines
  static const Color border = Color(0xFFE2E6EE);
  static const Color divider = Color(0xFFE4E8EF);
  static const Color borderStrong = Color(0xFFCBD3DF);

  /// Soft elevation used on every card. Deliberately low-contrast: a national
  /// ID app should read as paper, not as a stack of floating panels.
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0F16202E),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  /// Credential card only. Kept soft and close: a large offset renders as a
  /// solid grey band under the card rather than as lift.
  static List<BoxShadow> get raisedShadow => const [
        BoxShadow(
          color: Color(0x1416202E),
          blurRadius: 22,
          offset: Offset(0, 6),
          spreadRadius: -4,
        ),
      ];
}
