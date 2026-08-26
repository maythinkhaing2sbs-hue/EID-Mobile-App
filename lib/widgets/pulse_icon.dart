import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A solid gradient icon disc with rings that ping outward from behind it.
///
/// Used on screens where the app is waiting on something the user cannot see —
/// an SMS arriving, a reader connecting. The rings say "listening" without a
/// spinner, which would imply the *app* is busy rather than the world.
///
/// Every animation here is finite. A perpetually pulsing icon is visual noise
/// on a screen the user has to concentrate on, and an endlessly-scheduled frame
/// would also hang any `pumpAndSettle` in a test that lands on this screen.
class PulseIcon extends StatefulWidget {
  const PulseIcon({
    super.key,
    required this.icon,
    this.size = 104,
    this.pulses = 3,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final double size;

  /// How many rings leave the disc before the screen settles.
  final int pulses;
  final Color color;

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1150 * widget.pulses),
  )..forward();

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
                pulses: widget.pulses,
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.color, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.32),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  size: widget.size * 0.42,
                  color: Colors.white,
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
    required this.pulses,
    required this.color,
    required this.discRadius,
  });

  final double progress;
  final int pulses;
  final Color color;
  final double discRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    // Fades the whole effect out as the animation ends, so the last ring does
    // not freeze on screen at full strength.
    final envelope = (1 - progress * progress).clamp(0.0, 1.0);
    if (envelope <= 0) return;

    // Two ring trains half a cycle apart, so the pings overlap rather than
    // arriving one at a time.
    for (var train = 0; train < 2; train++) {
      final local = ((progress * pulses) + train * 0.5) % 1.0;
      final radius = discRadius + (maxRadius - discRadius) * local;
      final opacity = (1 - local) * 0.30 * envelope;
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
