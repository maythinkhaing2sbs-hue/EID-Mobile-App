import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'icon_motion.dart';

/// An icon disc with rings that ping outward from behind it.
///
/// Used on screens where the app is waiting on something the user cannot see —
/// a code arriving, a reader connecting. The rings say "listening" without a
/// spinner, which would imply the *app* is busy rather than the world.
///
/// The rings loop for as long as the screen is up. The wait they describe has
/// not ended either, and a graphic that stops after three pings quietly says
/// it has. Anything that needs this tree to reach a resting state — a widget
/// test — must drive it with `pump(duration)` rather than `pumpAndSettle()`.
class PulseIcon extends StatefulWidget {
  const PulseIcon({
    super.key,
    required this.icon,
    this.size = 104,
    this.color = AppColors.primary,
    this.fill,
    this.iconColor,
    this.motion = IconMotion.none,
  });

  final IconData icon;
  final double size;

  /// Ring colour, and the base of the disc gradient when [fill] is null.
  final Color color;

  /// Flat disc colour. Left null for the brand gradient; set to a tint — the
  /// pale blue the PIN badge uses, say — when the disc sits directly above the
  /// heading and a solid block of brand would outshout it.
  final Color? fill;

  /// Glyph colour. Defaults to white on the gradient and to [color] on a tint.
  final Color? iconColor;

  /// How the glyph inside the disc keeps moving. See [IconMotion].
  final IconMotion motion;

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon> with TickerProviderStateMixin {
  /// One-shot: the disc arrives once and then stays put.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  /// Perpetual: one ring leaves the disc every cycle, two trains half a cycle
  /// apart so the pings overlap instead of arriving one at a time.
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final Animation<double> _pop = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _entrance.dispose();
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The rings need room to travel beyond the disc.
    final double extent = widget.size * 1.7;
    final bool tinted = widget.fill != null;
    final Color glyphColour =
        widget.iconColor ?? (tinted ? widget.color : Colors.white);

    return SizedBox(
      height: extent,
      width: extent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ping,
            builder: (context, _) => CustomPaint(
              size: Size.square(extent),
              painter: _RingPainter(
                progress: _ping.value,
                color: widget.color,
                discRadius: widget.size / 2,
              ),
            ),
          ),
          ScaleTransition(
            scale: _pop,
            child: FadeTransition(
              opacity: _entrance,
              child: Container(
                height: widget.size,
                width: widget.size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.fill,
                  gradient: tinted
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [widget.color, AppColors.primaryDark],
                        ),
                  // A tinted disc is already quiet; a coloured drop shadow
                  // under it just muddies the pale fill.
                  boxShadow: tinted
                      ? null
                      : [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.32),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                            spreadRadius: -6,
                          ),
                        ],
                ),
                child: MotionGlyph(
                  icon: widget.icon,
                  size: widget.size * 0.42,
                  color: glyphColour,
                  motion: widget.motion,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.discRadius,
  });

  final double progress;
  final Color color;
  final double discRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    for (var train = 0; train < 2; train++) {
      final local = (progress + train * 0.5) % 1.0;
      final radius = discRadius + (maxRadius - discRadius) * local;

      // Each ring fades as it travels, so no ring ever reaches the edge of the
      // box and vanishes at full strength.
      final opacity = (1 - local) * 0.30;
      if (opacity <= 0.01) continue;

      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
/// Fades and lifts its child into place once, on first build.
///
/// Applied to the body of screens the user arrives at rather than scrolls to,
/// so the content settles instead of snapping in.
///
/// The stagger is an [Interval] on a controller that starts immediately, not a
/// delayed `forward()`. That matters: a child that begins at opacity 0 and
/// waits on a timer is *invisible* until that timer fires, so anything which
/// does not pump the clock — a screenshot harness, a widget test, a dropped
/// frame during a route transition — can catch it blank. With an interval there
/// is no waiting callback to miss.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;

  /// How long to hold before this child begins its entrance.
  final Duration delay;

  /// How far below its resting place the child starts, in logical pixels.
  final double offset;

  static const Duration _travel = Duration(milliseconds: 420);

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final Duration _total = widget.delay + FadeSlideIn._travel;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _total.inMicroseconds == 0
          ? 0
          : widget.delay.inMicroseconds / _total.inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Pops its child into place once, on first build: a short fade with a scale
/// that overshoots slightly and settles.
///
/// For the milestone mark at the top of a screen, where [FadeSlideIn]'s upward
/// lift reads as "there is more content below" rather than "here is the thing
/// this screen is about".
///
/// Uses the same interval-not-timer stagger as [FadeSlideIn], and for the same
/// reason: a child held at opacity 0 by a pending callback can be caught blank
/// by anything that does not pump the clock.
class ScaleIn extends StatefulWidget {
  const ScaleIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = 0.84,
  });

  final Widget child;

  /// How long to hold before this child begins its entrance.
  final Duration delay;

  /// Scale the child starts at, as a fraction of its resting size.
  final double from;

  static const Duration _travel = Duration(milliseconds: 480);

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late final Duration _total = widget.delay + ScaleIn._travel;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _total,
  )..forward();

  late final double _start = _total.inMicroseconds == 0
      ? 0
      : widget.delay.inMicroseconds / _total.inMicroseconds;

  /// Scale overshoots; opacity must not, so the two ride different curves off
  /// the same controller rather than sharing one.
  late final Animation<double> _scale = Tween<double>(
    begin: widget.from,
    end: 1,
  ).animate(CurvedAnimation(
    parent: _c,
    curve: Interval(_start, 1, curve: Curves.easeOutBack),
  ));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Interval(_start, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
