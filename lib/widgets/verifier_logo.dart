import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// The requesting party's brand mark.
///
/// Drawn rather than shipped as a bitmap: a verifier's logo arrives from the
/// trust registry at whatever size it happens to be, and a wallet that scales
/// a stranger's PNG into a 52pt tile produces mush at exactly the moment the
/// user is deciding whether to trust them. A vector mark stays crisp at every
/// density, needs no network fetch on a consent screen, and cannot carry a
/// tracking pixel.
///
/// Banks get the neoclassical emblem — pediment, columns, plinth — which is
/// what the category has meant on signage for two centuries and reads at 20pt.
/// Anything else falls back to a monogram of its initials.
class VerifierLogo extends StatelessWidget {
  const VerifierLogo({
    super.key,
    required this.name,
    this.size = 52,
    this.onDark = true,
  });

  final String name;
  final double size;

  /// True when the logo sits on the brand gradient, which calls for a white
  /// lockup tile; false on a white surface, where the tile takes the brand
  /// tint instead so it does not disappear.
  final bool onDark;

  /// The mark itself is always brand blue — it is the one constant between the
  /// two grounds, so the same logo is recognisably the same object on both.
  static const List<Color> _ink = [Color(0xFF2F7BE0), Color(0xFF16407D)];

  /// The glyph knocked out of the roundel. Not flat white: the faint fall-off
  /// towards the bottom right is what stops the building reading as a sticker
  /// pasted on a circle.
  static const List<Color> _relief = [Color(0xFFFFFFFF), Color(0xFFD7E6FB)];

  bool get _isBank {
    final n = name.toLowerCase();
    return n.contains('bank') || n.contains('ဘဏ်');
  }

  /// Up to two initials from the leading words — "Yangon City Hall" → "YC".
  String get _initials {
    final words = name
        .split(RegExp(r'[\s\-_]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final letters = words.take(2).map((w) => w.characters.first).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: onDark
              ? const [Color(0xFFFFFFFF), Color(0xFFE8F0FC)]
              : const [Color(0xFFF2F7FE), AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: onDark
              ? Colors.white
              : AppColors.primary.withValues(alpha: 0.16),
        ),
        boxShadow: onDark
            ? const [
                BoxShadow(
                  color: Color(0x33101B2E),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: _isBank
            // The glyph sits knocked out of a solid roundel rather than
            // straight on the tile. A line-art building on a white square is
            // what a system icon looks like; a mark inside a filled disc is
            // what a bank's brand looks like, and the two are being told apart
            // at a glance on a consent screen.
            ? Container(
                height: size * 0.72,
                width: size * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _ink,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.last.withValues(alpha: 0.28),
                      blurRadius: size * 0.14,
                      offset: Offset(0, size * 0.05),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: Size.square(size * 0.4),
                    painter: const _BankMark(colors: _relief),
                  ),
                ),
              )
            : ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _ink,
                ).createShader(rect),
                child: Text(
                  _initials,
                  style: AppTypography.numeric(
                    size: size * 0.36,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    spacing: 0.5,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Pediment, three columns, plinth. Proportions are set as fractions of the
/// box so the mark is identical at 20pt and at 56pt.
class _BankMark extends CustomPainter {
  const _BankMark({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(Offset.zero & size);

    // Pediment. The apex is clipped flat by a hair so it does not render as a
    // single stray pixel at small sizes.
    final roof = Path()
      ..moveTo(w * 0.46, h * 0.02)
      ..lineTo(w * 0.54, h * 0.02)
      ..lineTo(w * 0.99, h * 0.28)
      ..lineTo(w * 0.01, h * 0.28)
      ..close();
    canvas.drawPath(roof, paint);

    // Columns.
    const centres = [0.215, 0.5, 0.785];
    final colWidth = w * 0.15;
    for (final c in centres) {
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          w * c - colWidth / 2,
          h * 0.37,
          w * c + colWidth / 2,
          h * 0.79,
          topLeft: Radius.circular(w * 0.03),
          topRight: Radius.circular(w * 0.03),
        ),
        paint,
      );
    }

    // Plinth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, h * 0.86, w, h),
        Radius.circular(w * 0.035),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BankMark oldDelegate) => oldDelegate.colors != colors;
}
