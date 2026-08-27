import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';

/// The one saturated surface in the product: brand gradient, two soft discs
/// bleeding off the edge, and a band of light that crosses occasionally.
///
/// It is reserved for the objects that *are* the identity — the credential
/// about to be issued, and the party asking to see it. The light sweeping
/// across the gradient is the cue a physical card gives when you tilt it: it
/// says *this is the real thing* far faster than any label, and it keeps a
/// screen of static text from reading as dead.
class BrandPanel extends StatefulWidget {
  const BrandPanel({
    super.key,
    required this.child,
    this.borderRadius = Radii.cardAll,
    this.padding = Insets.cardLoose,
    this.shadow = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  /// Lift, for a panel that stands alone as a card. Omitted when the panel is
  /// the top slab of a larger card and has to sit flush against it.
  final bool shadow;

  @override
  State<BrandPanel> createState() => _BrandPanelState();
}

class _BrandPanelState extends State<BrandPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: widget.shadow ? AppColors.raisedShadow : null,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
              ),
            ),
            // Two soft discs bleeding off the edge — the guilloche of a
            // printed card, reduced to something that survives at this size.
            const Positioned(right: -34, top: -46, child: _Disc(size: 128)),
            const Positioned(right: 40, bottom: -54, child: _Disc(size: 92)),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sheen,
                builder: (context, _) => _Sheen(t: _sheen.value),
              ),
            ),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );
  }
}

/// A decorative disc, faint enough to read as texture rather than as content.
class _Disc extends StatelessWidget {
  const _Disc({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

/// A band of light crossing the panel, then resting off-screen for most of the
/// cycle. A sheen that never stops moving is jewellery; one that passes
/// occasionally is a card catching the light.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    const travel = 0.42;
    final p = -0.25 +
        1.55 * Curves.easeInOut.transform((t / travel).clamp(0.0, 1.0));

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: [
            (p - 0.16).clamp(0.0, 1.0),
            p.clamp(0.0, 1.0),
            (p + 0.16).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

/// A chip for a coloured ground: the solid tinted pill used elsewhere turns to
/// mud on blue, so this one is glass.
class GlassBadge extends StatelessWidget {
  const GlassBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: Radii.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.textOnPrimary),
            Gap.w4,
          ],
          Text(
            label,
            // The smallest label in the scale: this is an attribute of the
            // name above it, and at the previous size it read as a second
            // heading competing with the credential.
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
