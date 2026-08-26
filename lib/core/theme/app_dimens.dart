import 'package:flutter/widgets.dart';

/// Spacing scale — a 4pt grid. Screens only ever use these values so vertical
/// rhythm stays identical across the 15 flows.
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const SizedBox h4 = SizedBox(height: xs);
  static const SizedBox h8 = SizedBox(height: sm);
  static const SizedBox h12 = SizedBox(height: md);
  static const SizedBox h16 = SizedBox(height: lg);
  static const SizedBox h24 = SizedBox(height: xl);
  static const SizedBox h32 = SizedBox(height: xxl);
  static const SizedBox h48 = SizedBox(height: xxxl);

  static const SizedBox w4 = SizedBox(width: xs);
  static const SizedBox w8 = SizedBox(width: sm);
  static const SizedBox w12 = SizedBox(width: md);
  static const SizedBox w16 = SizedBox(width: lg);
}

abstract final class Radii {
  static const Radius card = Radius.circular(16);
  static const Radius field = Radius.circular(12);
  static const Radius chip = Radius.circular(999);

  static const BorderRadius cardAll = BorderRadius.all(card);
  static const BorderRadius fieldAll = BorderRadius.all(field);
  static const BorderRadius pill = BorderRadius.all(chip);
}

abstract final class Insets {
  /// Horizontal page gutter. 20 rather than 16 — Myanmar text is visually
  /// dense and needs a little more air at the edge of the screen.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets card = EdgeInsets.all(Gap.lg);
  static const EdgeInsets cardLoose = EdgeInsets.all(Gap.xl);
}

/// Minimum tap target, per Material and WCAG 2.5.5.
const double kMinTapTarget = 48;
