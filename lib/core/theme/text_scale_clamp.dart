import 'package:flutter/material.dart';

/// Caps how far the OS text-size setting may enlarge the app's type.
///
/// Myanmar script at 2.0× breaks the fixed-height credential card and the OTP
/// boxes, so the ceiling keeps the app usable for low-vision users without
/// shredding the layout.
///
/// Only a *ceiling* is applied — deliberately. Setting `minScaleFactor: 1`
/// looks harmless but is not:
///
///  * It overrides people who have *reduced* their system font size, which is
///    a legitimate preference the app has no business vetoing.
///  * It crashes the Material date picker. That widget re-clamps its header to
///    a max of exactly 1.0, and `_ClampedTextScaler.clamp` composes bounds as
///    `min(newMax, oldMax)` / `max(newMin, oldMin)`, yielding `min == max ==
///    1.0` — which trips its own `assert(maxScale > minScale)`. Any descendant
///    clamping its maximum down to the outer minimum hits this.
class AppTextScaleClamp extends StatelessWidget {
  const AppTextScaleClamp({
    super.key,
    required this.child,
    this.maxScaleFactor = 1.3,
  });

  final Widget child;
  final double maxScaleFactor;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(maxScaleFactor: maxScaleFactor),
      ),
      child: child,
    );
  }
}
