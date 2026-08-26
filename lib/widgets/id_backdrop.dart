import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The welcome screen's wallpaper: the visual language of a real identity
/// document, painted rather than shipped as a photo.
///
/// Every motif here is one a citizen has physically seen on an ID card, and
/// that is the point — the screen should read as "this is your ID", not as a
/// generic app splash:
///
/// * **Guilloché rosettes** — the interlaced engine-turned curves printed on
///   passports and banknotes as an anti-counterfeit feature.
/// * **A ghosted credential card** — portrait window, chip, data lines.
/// * **A fingerprint** — the biometric half of the identity.
/// * **Microline hatching and a dot grid** — the security substrate.
///
/// All of it is drawn at very low alpha in the brand blue, so the page still
/// reads as white and body copy keeps its contrast ratio. The whole thing is
/// pure trigonometry with no randomness, so it renders identically every frame
/// and is cached in a [RepaintBoundary].
class IdBackdrop extends StatelessWidget {
  const IdBackdrop({super.key, this.child, this.intensity = 1});

  final Widget? child;

  /// Scales every motif's opacity. Below 1 for screens with dense copy on top.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.surface),
        RepaintBoundary(
          child: CustomPaint(
            painter: _IdBackdropPainter(intensity: intensity),
            isComplex: true,
            willChange: false,
            size: Size.infinite,
          ),
        ),
        ?child,
      ],
    );
  }
}

class _IdBackdropPainter extends CustomPainter {
  const _IdBackdropPainter({required this.intensity});

  final double intensity;

  /// Brand blue at [a] × [intensity]. Clamped so a caller passing a large
  /// intensity cannot push the wallpaper into the foreground.
  Color _ink(double a) =>
      AppColors.primary.withValues(alpha: (a * intensity).clamp(0, 0.5));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.clipRect(Offset.zero & size);

    _paintWash(canvas, w, h);
    _paintDotGrid(canvas, w, h);
    _paintMicrolines(canvas, w, h);
    _paintGuilloche(canvas, Offset(w * 0.86, h * 0.12), w * 0.42);
    _paintGuilloche(canvas, Offset(w * 0.08, h * 0.78), w * 0.34);
    _paintGhostCard(canvas, w, h);
    _paintFingerprint(canvas, Offset(w * 0.84, h * 0.86), w * 0.20);
  }

  // ── Substrate ──────────────────────────────────────────────────────────

  /// Two soft corner washes. Keeps the page from reading as flat paper without
  /// introducing a gradient strong enough to fight the card above it.
  void _paintWash(Canvas canvas, double w, double h) {
    void wash(Offset centre, double radius, double alpha) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [_ink(alpha), _ink(0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }

    wash(Offset(w * 0.92, h * 0.02), w * 0.95, 0.10);
    wash(Offset(w * 0.02, h * 0.92), w * 0.85, 0.07);
  }

  /// The regular dot field printed under the laminate on a modern ID card.
  void _paintDotGrid(Canvas canvas, double w, double h) {
    const step = 22.0;
    final dot = Paint()..color = _ink(0.055);
    for (var y = step; y < h; y += step) {
      for (var x = step; x < w; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  /// Diagonal microline hatching, fading out across the page so it never sits
  /// at full strength behind the headline.
  void _paintMicrolines(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 13.0;
    final diagonal = w + h;
    for (var i = 0.0; i < diagonal; i += spacing) {
      // Alternating weight is what gives real microprint its moiré shimmer.
      final t = (i / diagonal);
      final base = (i / spacing).round().isEven ? 0.05 : 0.028;
      paint.color = _ink(base * (1 - t * 0.7));
      canvas.drawLine(Offset(i, 0), Offset(i - h, h), paint);
    }
  }

  // ── Motifs ─────────────────────────────────────────────────────────────

  /// Guilloché rosette — a family of hypotrochoids sharing a centre. The three
  /// radii below were chosen so the curves close cleanly and interlace rather
  /// than overlap into a solid disc.
  void _paintGuilloche(Canvas canvas, Offset centre, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = _ink(0.13);

    for (final petals in [7, 11, 17]) {
      final r = radius / petals;
      final d = r * (petals == 11 ? 2.4 : 1.9);
      final path = Path();

      // 0.5° steps: fine enough that the curve reads as engraving, coarse
      // enough to stay cheap on a low-end handset.
      for (var deg = 0; deg <= 360 * 2; deg++) {
        final t = deg * math.pi / 360;
        final k = radius - r;
        final p = Offset(
          centre.dx + k * math.cos(t) + d * math.cos(k / r * t),
          centre.dy + k * math.sin(t) - d * math.sin(k / r * t),
        );
        deg == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
      paint.color = _ink(0.085);
    }

    // Concentric guide rings, as on the printed original.
    for (final f in [0.42, 0.66, 1.0]) {
      canvas.drawCircle(
        centre,
        radius * f,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _ink(0.07),
      );
    }
  }

  /// A credential in outline: the object the whole app is about, ghosted into
  /// the paper at ID-1 proportions (85.6 × 54 mm) and tilted like a card laid
  /// on a desk.
  void _paintGhostCard(Canvas canvas, double w, double h) {
    final cardW = w * 0.66;
    final cardH = cardW * 54 / 85.6;

    // Held high, above where a centred hero card lands: the motif is wallpaper,
    // and behind a card it stops reading as an ID and starts reading as a smudge.
    final origin = Offset(w * 0.05, h * 0.035);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(-0.12);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _ink(0.16);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardW, cardH),
      const Radius.circular(14),
    );
    canvas.drawRRect(body, Paint()..color = _ink(0.03));
    canvas.drawRRect(body, stroke);

    final pad = cardH * 0.12;

    // Portrait window.
    final portraitW = cardW * 0.24;
    final portrait = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, pad, portraitW, cardH - pad * 2),
      const Radius.circular(6),
    );
    canvas.drawRRect(portrait, stroke..color = _ink(0.13));

    // Head-and-shoulders glyph inside it.
    final cx = pad + portraitW / 2;
    final headR = portraitW * 0.19;
    canvas.drawCircle(
      Offset(cx, pad + (cardH - pad * 2) * 0.34),
      headR,
      Paint()..color = _ink(0.11),
    );
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCenter(
            center: Offset(cx, pad + (cardH - pad * 2) * 0.92),
            width: portraitW * 0.72,
            height: portraitW * 0.72,
          ),
          math.pi,
          math.pi,
        ),
      Paint()..color = _ink(0.11),
    );

    // Data lines of decreasing length — name, number, dates.
    final lineX = pad * 2 + portraitW;
    final lineW = cardW - lineX - pad;
    const widths = [1.0, 0.78, 0.9, 0.55];
    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cardH * 0.045
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < widths.length; i++) {
      final y = pad + cardH * 0.14 + i * cardH * 0.17;
      linePaint.color = _ink(i == 0 ? 0.15 : 0.09);
      canvas.drawLine(
        Offset(lineX, y),
        Offset(lineX + lineW * widths[i], y),
        linePaint,
      );
    }

    // Contact chip: six contacts inside a rounded pad.
    final chip = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardW - pad - cardH * 0.2, cardH - pad - cardH * 0.16,
          cardH * 0.2, cardH * 0.16),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      chip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _ink(0.14),
    );
    for (var i = 1; i < 3; i++) {
      final y = chip.top + chip.height * i / 3;
      canvas.drawLine(
        Offset(chip.left, y),
        Offset(chip.right, y),
        Paint()
          ..strokeWidth = 0.8
          ..color = _ink(0.10),
      );
    }

    canvas.restore();
  }

  /// Fingerprint: nested arcs around a core, the way a loop pattern actually
  /// runs — open on one side rather than closed rings.
  void _paintFingerprint(Canvas canvas, Offset centre, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6;

    const ridges = 9;
    for (var i = 1; i <= ridges; i++) {
      final f = i / ridges;
      paint.color = _ink(0.115 - f * 0.045);
      canvas.drawArc(
        Rect.fromCenter(
          center: centre,
          width: radius * f * 1.55,
          height: radius * f * 2,
        ),
        // Each ridge opens a little wider at the base, as a real print does.
        -math.pi * 0.92 - f * 0.12,
        math.pi * (1.84 + f * 0.24),
        false,
        paint,
      );
    }

    // The core: a short vertical stroke the ridges wrap around.
    canvas.drawLine(
      Offset(centre.dx, centre.dy - radius * 0.16),
      Offset(centre.dx, centre.dy + radius * 0.26),
      paint..color = _ink(0.13),
    );
  }

  @override
  bool shouldRepaint(_IdBackdropPainter old) => old.intensity != intensity;
}
