import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The wallet's brand mark: a national shield with a digital-credential motif.
///
/// Drawn rather than shipped as a raster so it stays crisp at every size and
/// can be tinted for light chrome (app bars) without a second asset.
class EidLogo extends StatelessWidget {
  const EidLogo({super.key, this.size = 72, this.monochrome});

  final double size;

  /// When set, the whole mark is painted in this single colour — used inside
  /// app bars and on coloured backgrounds.
  final Color? monochrome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(
        painter: _ShieldPainter(monochrome: monochrome),
        isComplex: true,
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({this.monochrome});

  final Color? monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Shield silhouette ────────────────────────────────────────────────
    final shield = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.94, h * 0.16)
      ..lineTo(w * 0.94, h * 0.55)
      // Sweep down to the point: two mirrored quadratics keep the shoulders
      // soft while the tip stays sharp.
      ..quadraticBezierTo(w * 0.94, h * 0.86, w * 0.5, h)
      ..quadraticBezierTo(w * 0.06, h * 0.86, w * 0.06, h * 0.55)
      ..lineTo(w * 0.06, h * 0.16)
      ..close();

    final body = Paint()
      ..shader = monochrome != null
          ? null
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..color = monochrome ?? AppColors.primary;
    canvas.drawPath(shield, body);

    final mark = Paint()..color = monochrome != null ? Colors.white : Colors.white;

    // ── Star: the national/official half of the mark ─────────────────────
    _drawStar(
      canvas,
      Offset(w * 0.5, h * 0.34),
      outer: w * 0.19,
      inner: w * 0.082,
      paint: mark,
    );

    // ── Credential lines: the digital half ───────────────────────────────
    // Three stacked bars of decreasing width read as a document / data record.
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = h * 0.045
      ..style = PaintingStyle.stroke;

    const widths = [0.34, 0.26, 0.18];
    for (var i = 0; i < widths.length; i++) {
      final y = h * (0.545 + i * 0.088);
      final half = w * widths[i] / 2;
      canvas.drawLine(
        Offset(w * 0.5 - half, y),
        Offset(w * 0.5 + half, y),
        barPaint..color = Colors.white.withValues(alpha: 0.92 - i * 0.22),
      );
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset centre, {
    required double outer,
    required double inner,
    required Paint paint,
  }) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final p = Offset(
        centre.dx + r * math.cos(angle),
        centre.dy + r * math.sin(angle),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.monochrome != monochrome;
}

/// Logo + wordmark, used on the Welcome screen and the wallet home header.
class EidLockup extends StatelessWidget {
  const EidLockup({
    super.key,
    required this.title,
    this.subtitle,
    this.logoSize = 64,
  });

  final String title;
  final String? subtitle;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        EidLogo(size: logoSize),
        const SizedBox(height: 16),
        Text(title, style: text.titleLarge, textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
