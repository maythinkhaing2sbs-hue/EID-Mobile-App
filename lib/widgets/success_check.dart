import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';

/// The success mark used on "Wallet Ready", "Key Pair Created", "Credential
/// Issued" and "Verification Successful".
///
/// Animated in two beats — the ring scales in, then the tick draws itself —
/// because an instantly-complete checkmark reads as a static icon, while a
/// drawn one reads as *something just finished*.
///
/// Once drawn, the mark keeps a slow heartbeat: a ring leaves the disc and the
/// disc breathes with it. The tick is never re-drawn — undrawing a completed
/// mark would say the thing had come *undone* — so what loops is only the
/// signal that the result is live. Pass `pulse: false` for a mark inside a
/// list, where a heartbeat is noise.
///
/// The heartbeat never settles, so a widget test that lands on a screen using
/// this must drive the clock with `pump(duration)`, not `pumpAndSettle()`.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({
    super.key,
    this.size = 96,
    this.color = AppColors.success,
    this.haptic = true,
    this.pulse = true,
  });

  final double size;
  final Color color;
  final bool haptic;

  /// Whether the mark keeps its heartbeat after the tick has landed.
  final bool pulse;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..forward();

  /// The heartbeat. Its own controller, because the draw is one-shot and
  /// folding the two together would re-draw the tick on every beat.
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final Animation<double> _ring = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
  );

  late final Animation<double> _tick = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _beat.repeat();
    if (widget.haptic) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => HapticFeedback.mediumImpact(),
      );
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_c, _beat]),
        builder: (context, _) => CustomPaint(
          painter: _CheckPainter(
            ring: _ring.value,
            tick: _tick.value,
            // The heartbeat only starts once the tick has landed, so the two
            // motions never overlap.
            beat: widget.pulse && _c.isCompleted ? _beat.value : 0,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({
    required this.ring,
    required this.tick,
    required this.beat,
    required this.color,
  });

  final double ring;
  final double tick;

  /// Position in the heartbeat cycle, 0 when there is none.
  final double beat;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.width / 2;

    // Halo
    canvas.drawCircle(
      centre,
      r * ring,
      Paint()..color = color.withValues(alpha: 0.12),
    );

    // Heartbeat: one ring leaves the disc per cycle and fades into the halo,
    // and the disc swells a hair as it goes.
    var swell = 1.0;
    if (beat > 0) {
      final travel = Curves.easeOutCubic.transform(beat);
      final alpha = (1 - beat) * 0.34;
      if (alpha > 0.01) {
        canvas.drawCircle(
          centre,
          r * (0.76 + 0.24 * travel),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: alpha),
        );
      }
      swell = 1 + 0.028 * math.sin(beat * math.pi * 2);
    }

    // Disc
    canvas.drawCircle(
      centre,
      r * 0.76 * ring * swell,
      Paint()..color = color,
    );

    if (tick <= 0) return;

    // Tick, drawn as a two-segment stroke revealed left-to-right.
    final p1 = Offset(size.width * 0.34, size.height * 0.52);
    final p2 = Offset(size.width * 0.45, size.height * 0.63);
    final p3 = Offset(size.width * 0.67, size.height * 0.40);

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(p1.dx, p1.dy);
    const split = 0.38; // first segment is the shorter of the two
    if (tick <= split) {
      final t = tick / split;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final t = (tick - split) / (1 - split);
      path
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.ring != ring ||
      old.tick != tick ||
      old.beat != beat ||
      old.color != color;
}

/// Full-screen confirmation layout shared by every "done" screen: mark,
/// headline, supporting line, then the caller's own detail block.
class SuccessLayout extends StatelessWidget {
  const SuccessLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.detail,
    this.checkColor = AppColors.success,
  });

  final String title;
  final String? subtitle;
  final Widget? detail;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: SuccessCheck(color: checkColor)),
        Gap.h32,
        Text(title, style: text.headlineMedium, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          Gap.h12,
          Text(subtitle!, style: text.bodyMedium, textAlign: TextAlign.center),
        ],
        if (detail != null) ...[Gap.h32, detail!],
      ],
    );
  }
}

/// A single line in a "what is happening right now" list — used while the
/// issuer signs a credential and while the reader verifies one.
enum StepStatus { pending, active, done }

class ProcessStep extends StatelessWidget {
  const ProcessStep({super.key, required this.label, required this.status});

  final String label;
  final StepStatus status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final Widget leading = switch (status) {
      StepStatus.done => const Icon(Icons.check_circle_rounded,
          size: 20, color: AppColors.success),
      StepStatus.active => const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      StepStatus.pending => const Icon(Icons.circle_outlined,
          size: 20, color: AppColors.borderStrong),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(width: 20, height: 20, child: Center(child: leading)),
          Gap.w12,
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: (text.bodyLarge ?? const TextStyle()).copyWith(
                fontSize: 15,
                color: status == StepStatus.pending
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
                fontWeight: status == StepStatus.active
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
