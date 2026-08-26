import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The product mark, shipped as `assets/image/logo.jpg`.
///
/// The source file is a JPEG, so it carries a hard white matte rather than
/// transparency. On the welcome screen it sits over a patterned backdrop, and
/// that matte would read as a bare white rectangle — so by default the mark is
/// set on a deliberate rounded plate with a hairline and a soft shadow, which
/// turns the matte into part of the design instead of an artefact.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 72,
    this.plate = true,
    this.padding = 14,
  });

  /// Height of the mark itself, excluding any plate padding.
  final double height;

  /// White card behind the mark. Turn off only on a surface that is already
  /// pure white and unpatterned.
  final bool plate;

  final double padding;

  /// Aspect ratio of the shipped artwork (262 × 229). Reserving the width up
  /// front stops the row collapsing to zero-width while the JPEG decodes and
  /// then snapping open once it does. A replacement mark of another shape is
  /// letterboxed by [BoxFit.contain] rather than distorted.
  static const double _aspect = 262 / 229;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/image/logo.jpg',
      height: height,
      width: height * _aspect,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'EID Wallet',
      // A missing or undeclared asset must not blank the brand area.
      errorBuilder: (context, error, stack) => Icon(
        Icons.badge_outlined,
        size: height,
        color: AppColors.primary,
      ),
    );

    if (!plate) return image;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(height * 0.32),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: image,
    );
  }
}
