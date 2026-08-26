import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// QR viewfinder overlay: dimmed surround, clear square aperture, corner
/// brackets, and a sweeping scan line.
///
/// The camera preview itself belongs to whichever scanner plugin the project
/// adopts; this widget is the chrome that sits on top of it, so swapping the
/// camera implementation never touches the design.
class ScannerFrame extends StatefulWidget {
  const ScannerFrame({
    super.key,
    this.apertureFactor = 0.68,
    this.preview,
    this.caption,
  });

  /// Aperture width as a fraction of the shorter screen edge.
  final double apertureFactor;

  /// The live camera preview. When null a neutral placeholder is drawn so the
  /// screen is fully reviewable on a simulator or in a design walkthrough.
  final Widget? preview;

  final Widget? caption;

  @override
  State<ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<ScannerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final aperture = shortest * widget.apertureFactor;
        final rect = Rect.fromCenter(
          center: Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight * 0.44,
          ),
          width: aperture,
          height: aperture,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.preview ?? const _PreviewPlaceholder(),
            // Dim everything except the aperture.
            IgnorePointer(
              child: CustomPaint(painter: _MaskPainter(rect: rect)),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) => CustomPaint(
                  painter: _BracketPainter(
                    rect: rect,
                    sweep: Curves.easeInOut.transform(_sweep.value),
                  ),
                ),
              ),
            ),
            if (widget.caption != null)
              Positioned(
                left: 24,
                right: 24,
                top: rect.bottom + 28,
                child: widget.caption!,
              ),
          ],
        );
      },
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF243040), Color(0xFF10161F)],
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  const _MaskPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, hole),
      Paint()..color = const Color(0xCC0B1017),
    );
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.rect != rect;
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.rect, required this.sweep});

  final Rect rect;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 30.0;
    const radius = 24.0;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Four corner brackets: an L at each corner with a rounded elbow.
    void bracket(Offset corner, double dx, double dy) {
      final path = Path()
        ..moveTo(corner.dx + dx * arm, corner.dy)
        ..lineTo(corner.dx + dx * radius, corner.dy)
        ..quadraticBezierTo(
          corner.dx,
          corner.dy,
          corner.dx,
          corner.dy + dy * radius,
        )
        ..lineTo(corner.dx, corner.dy + dy * arm);
      canvas.drawPath(path, paint);
    }

    bracket(rect.topLeft, 1, 1);
    bracket(rect.topRight, -1, 1);
    bracket(rect.bottomLeft, 1, -1);
    bracket(rect.bottomRight, -1, -1);

    // Sweep line with a soft gradient so it reads as light, not a hairline.
    final y = rect.top + rect.height * sweep;
    final band = Rect.fromLTRB(rect.left + 6, y - 26, rect.right - 6, y + 2);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0),
            AppColors.primary.withValues(alpha: 0.45),
          ],
        ).createShader(band),
    );
    canvas.drawLine(
      Offset(rect.left + 6, y),
      Offset(rect.right - 6, y),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.sweep != sweep || old.rect != rect;
}
