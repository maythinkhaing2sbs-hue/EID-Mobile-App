import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How a glyph keeps moving while its screen is on show.
///
/// These loop on purpose. Each one is the picture of what the screen is
/// waiting for — a code landing in an inbox, a lock being turned — so the
/// motion carries meaning for as long as the user is still waiting, not just
/// for the half second after the route pushes.
enum IconMotion {
  /// No motion; the glyph simply sits there.
  none,

  /// Something arriving: the glyph drops in from above, settles with a small
  /// bounce, rests, and does it again.
  arrive,

  /// A key being turned: the glyph rocks through the turn, clicks home with a
  /// short scale, then relaxes and repeats.
  turn,

  /// Alive and finished: a slow, shallow breath. For marks that have already
  /// landed and only need to keep looking awake.
  breathe,
}

/// An [Icon] under a looping [IconMotion].
///
/// The whole cycle runs off one repeating controller with [Interval]s rather
/// than chained callbacks: a single controller is cheap to keep alive, stays in
/// step with itself after a rebuild, and there is no timer to leak if the
/// screen is popped mid-cycle.
///
/// Note for tests: a repeating controller never settles, so a widget test that
/// lands on a screen using this must drive the clock with `pump(duration)`
/// rather than `pumpAndSettle()`.
class MotionGlyph extends StatefulWidget {
  const MotionGlyph({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    this.motion = IconMotion.none,
  });

  final IconData icon;
  final double size;
  final Color color;
  final IconMotion motion;

  @override
  State<MotionGlyph> createState() => _MotionGlyphState();
}

class _MotionGlyphState extends State<MotionGlyph>
    with SingleTickerProviderStateMixin {
  static const Map<IconMotion, Duration> _periods = {
    IconMotion.none: Duration(milliseconds: 1),
    IconMotion.arrive: Duration(milliseconds: 2600),
    IconMotion.turn: Duration(milliseconds: 2800),
    IconMotion.breathe: Duration(milliseconds: 3200),
  };

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _periods[widget.motion]!,
  );

  @override
  void initState() {
    super.initState();
    if (widget.motion != IconMotion.none) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(widget.icon, size: widget.size, color: widget.color);
    if (widget.motion == IconMotion.none) return glyph;

    return AnimatedBuilder(
      animation: _c,
      child: glyph,
      builder: (context, child) => switch (widget.motion) {
        IconMotion.arrive => _arrive(child!, _c.value),
        IconMotion.turn => _turn(child!, _c.value),
        IconMotion.breathe => _breathe(child!, _c.value),
        IconMotion.none => child!,
      },
    );
  }

  /// Drop in (0–0.22), rest (–0.82), lift back out of frame (–1.0). The lift
  /// is what makes the next drop read as a *new* arrival rather than a jitter.
  Widget _arrive(Widget child, double t) {
    final double dy;
    final double opacity;

    if (t < 0.22) {
      final p = Curves.easeOutBack.transform(t / 0.22);
      dy = -widget.size * 0.75 * (1 - p);
      opacity = (t / 0.14).clamp(0.0, 1.0);
    } else if (t < 0.82) {
      dy = 0;
      opacity = 1;
    } else {
      final p = Curves.easeInCubic.transform((t - 0.82) / 0.18);
      dy = -widget.size * 0.5 * p;
      opacity = 1 - p;
    }

    return Opacity(
      opacity: opacity,
      child: Transform.translate(offset: Offset(0, dy), child: child),
    );
  }

  /// Wind up, turn, click, unwind. The scale bump lands exactly on the end of
  /// the turn, which is where a real lock gives.
  Widget _turn(Widget child, double t) {
    const double sweep = 0.30; // radians — a quarter turn reads as a spin
    final double angle;
    var scale = 1.0;

    if (t < 0.18) {
      angle = -sweep * 0.45 * Curves.easeInOut.transform(t / 0.18);
    } else if (t < 0.40) {
      final p = Curves.easeInOutBack.transform((t - 0.18) / 0.22);
      angle = -sweep * 0.45 + sweep * 1.45 * p;
    } else if (t < 0.52) {
      final p = (t - 0.40) / 0.12;
      angle = sweep * (1 - Curves.easeOutCubic.transform(p));
      scale = 1 + 0.10 * math.sin(p * math.pi);
    } else {
      angle = 0;
    }

    return Transform.rotate(
      angle: angle,
      child: Transform.scale(scale: scale, child: child),
    );
  }

  /// One slow swell per cycle. Deliberately shallow — this runs under content
  /// the user is reading.
  Widget _breathe(Widget child, double t) {
    final swell = math.sin(t * math.pi * 2) * 0.5 + 0.5;
    return Transform.scale(scale: 1 + 0.045 * swell, child: child);
  }
}
