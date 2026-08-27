import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/pulse_icon.dart';

/// Screen 7 — explain and create the Holder Key Pair.
///
/// This is the one screen in the flow that has to teach a concept, so it earns
/// its explanation: what a key pair is, why the wallet needs one, and the three
/// guarantees that follow from it. The action stays a single button — the user
/// is not being asked to make a cryptographic choice, only to proceed.
class CreateKeyPairScreen extends StatefulWidget {
  const CreateKeyPairScreen({super.key});

  @override
  State<CreateKeyPairScreen> createState() => _CreateKeyPairScreenState();
}

class _CreateKeyPairScreenState extends State<CreateKeyPairScreen> {
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    await WalletScope.read(context).createHolderKey();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushReplacementNamed(Routes.keyCreated);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: s.security,
      bottomBar: PrimaryButton(
        label: s.createKeyPair,
        busy: _busy,
        onPressed: _create,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          const Center(child: _KeyPairGraphic()),
          Gap.h32,
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: ScreenHeader(
                title: s.keyIntroTitle, subtitle: s.keyIntroBody),
          ),
          Gap.h24,

          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: AppCard(
              child: Column(
                children: [
                  _Point(
                      icon: Icons.phonelink_lock_outlined,
                      label: s.keyPointPrivate),
                  const Divider(height: Gap.xl),
                  _Point(icon: Icons.link_rounded, label: s.keyPointBinding),
                  const Divider(height: Gap.xl),
                  _Point(icon: Icons.draw_outlined, label: s.keyPointSign),
                ],
              ),
            ),
          ),

          Gap.h16,
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg, vertical: Gap.md),
            child: Row(
              children: [
                const Icon(Icons.vpn_key_outlined,
                    size: 20, color: AppColors.textTertiary),
                Gap.w12,
                Expanded(child: Text(s.holderKey, style: text.titleMedium)),
                StatusBadge(
                  label: s.keyStatusNotCreated,
                  tone: BadgeTone.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        Gap.w12,
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// Public / private key pair, drawn: two discs with the key material running
/// between them.
///
/// This is the one graphic in the app that has to *explain* rather than
/// decorate, so it animates the sentence the paragraph underneath is making —
/// the public half emits, the stream crosses, and only when it lands does the
/// private half come alive. Until then it sits in disabled grey: nothing is
/// protecting anything yet, and colouring it as though it were would be a lie
/// on the screen that asks the user to create it.
///
/// It loops, so a user who reads the paragraph first still sees the whole idea
/// when they look up. Each cycle ends by dimming the private half again, which
/// is what makes the next pass read as the same idea repeating rather than as a
/// second key arriving.
///
/// A repeating controller never settles, so a widget test landing here must
/// drive the clock with `pump(duration)` rather than `pumpAndSettle()`.
class _KeyPairGraphic extends StatefulWidget {
  const _KeyPairGraphic();

  @override
  State<_KeyPairGraphic> createState() => _KeyPairGraphicState();
}

class _KeyPairGraphicState extends State<_KeyPairGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// How alive the private half is: 0 while the stream is still crossing, 1
  /// once it has landed, and back to 0 as the cycle closes.
  static double _activation(double t) {
    if (t < 0.56) return 0;
    if (t < 0.66) {
      return Curves.easeOutBack.transform((t - 0.56) / 0.10).clamp(0.0, 1.0);
    }
    if (t < 0.88) return 1;
    return 1 - Curves.easeInCubic.transform((t - 0.88) / 0.12);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final live = _activation(_c.value);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ScaleIn(
                child: _Disc(
                  icon: Icons.vpn_key_rounded,
                  fill: AppColors.secondary,
                  iconColor: AppColors.primary,
                  caption: 'Public',
                ),
              ),

              // A wide channel, because the distance is the point: these are
              // two separate things, and the stream needs room to read as
              // travelling rather than as a join.
              Container(
                width: 104,
                height: 30,
                margin: const EdgeInsets.only(bottom: 24),
                child: CustomPaint(
                  painter: _StreamPainter(progress: _c.value, live: live),
                ),
              ),

              ScaleIn(
                delay: const Duration(milliseconds: 140),
                child: _Disc(
                  icon: Icons.lock_rounded,
                  // Grey until the key material arrives, then green — the
                  // colour the rest of the app reserves for "verified".
                  fill: Color.lerp(
                      AppColors.surfaceSunken, AppColors.success, live)!,
                  iconColor:
                      Color.lerp(AppColors.textTertiary, Colors.white, live)!,
                  caption: 'Private',
                  glow: live,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The key material crossing the gap: a rail with a train of dots running along
/// it, emitted by the public half and absorbed by the private one.
class _StreamPainter extends CustomPainter {
  const _StreamPainter({required this.progress, required this.live});

  final double progress;

  /// How lit the receiving disc is, so the rail can pick up its colour.
  final double live;

  /// Dots in flight at once, and how far apart they are launched. [_span] is
  /// what remains of the window after the last dot sets off, which is what
  /// keeps every dot landing inside the crossing rather than after it.
  static const int _dots = 4;
  static const double _lead = 0.12;
  static const double _span = 1 - _lead * (_dots - 1);

  /// The crossing occupies the middle of the cycle. The pause either side of it
  /// is what stops a loop from reading as a treadmill.
  static const double _start = 0.10;
  static const double _end = 0.60;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(AppColors.border,
            AppColors.success.withValues(alpha: 0.45), live)!,
    );

    if (progress < _start || progress > _end) return;
    final u = (progress - _start) / (_end - _start);

    for (var i = 0; i < _dots; i++) {
      final local = (u - i * _lead) / _span;
      if (local <= 0 || local >= 1) continue;

      // Absorbed rather than switched off: a dot fades as it reaches the
      // private disc, and fades up as it leaves the public one.
      final double alpha = local < 0.12
          ? local / 0.12
          : (local > 0.86 ? (1 - local) / 0.14 : 1.0);

      canvas.drawCircle(
        Offset(size.width * local, y),
        3.2,
        Paint()
          ..color = AppColors.primary.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_StreamPainter old) =>
      old.progress != progress || old.live != live;
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.icon,
    required this.fill,
    required this.iconColor,
    required this.caption,
    this.glow = 0,
  });

  final IconData icon;
  final Color fill;
  final Color iconColor;
  final String caption;

  /// How lit the disc is, 0–1. Drives a halo rather than another colour change,
  /// so the moment of arrival carries at a glance.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 76,
          width: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            boxShadow: glow <= 0
                ? null
                : [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.30 * glow),
                      blurRadius: 22 * glow,
                      spreadRadius: 2 * glow,
                    ),
                  ],
          ),
          child: Icon(icon, size: 32, color: iconColor),
        ),
        Gap.h8,
        Text(caption, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
