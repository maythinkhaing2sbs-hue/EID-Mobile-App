import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/success_check.dart';

/// The issuer-side half of screen 9: authorize → consent → bind key → sign →
/// store, then a hand-off to the request receipt.
///
/// Submitting takes real seconds and touches a government service, so the wait
/// is shown as named steps rather than a bare spinner. A user who is told what
/// is happening waits; a user watching an anonymous spinner force-quits.
///
/// What this screen never does is end in a credential. The seconds it covers
/// are the ones the wallet spends filing the application — approval takes days
/// and belongs to [CredentialPendingScreen], which replaces this screen once
/// the last step lands.
class CredentialIssuingScreen extends StatefulWidget {
  const CredentialIssuingScreen({super.key});

  @override
  State<CredentialIssuingScreen> createState() =>
      _CredentialIssuingScreenState();
}

class _CredentialIssuingScreenState extends State<CredentialIssuingScreen> {
  int _current = 0;

  static const _stepDurations = [
    Duration(milliseconds: 900),
    Duration(milliseconds: 700),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1100),
    Duration(milliseconds: 600),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < _stepDurations.length; i++) {
      await Future<void>.delayed(_stepDurations[i]);
      if (!mounted) return;
      setState(() => _current = i + 1);
    }

    if (!mounted) return;

    // The round-trip ends with the request *accepted*, not with a credential:
    // the issuer signs it only after a person has approved the application.
    // The wait that follows belongs to its own screen, which replaces this one
    // so the completed progress list is not left behind to walk back into.
    WalletScope.read(context).submitCredentialRequest();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      Routes.credentialPending,
      arguments: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    final steps = [
      s.stepAuthorize,
      s.stepConsent,
      s.stepBindKey,
      s.stepSign,
      s.stepStore,
    ];

    return AppScaffold(
      showBack: false,
      showLanguageToggle: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _IssuingHero(step: _current, total: steps.length),
          ),
          Gap.h32,
          ScreenHeader(
            title: s.issuingTitle,
            subtitle: s.pleaseWait,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          AppCard(
            // The step rows carry their own horizontal padding so the active
            // one can sit on a tinted pill; this trims the card's to match.
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.xs, vertical: Gap.md),
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  ProcessStep(
                    label: steps[i],
                    status: i < _current
                        ? StepStatus.done
                        : i == _current
                            ? StepStatus.active
                            : StepStatus.pending,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The waiting mark: a progress ring around a badge whose icon changes with
/// the step in flight.
///
/// A generic spinner says only "wait"; it cannot say *how long*, and after
/// three seconds it reads as a hang. This says both — the ring fills as real
/// work completes, and the icon names what the wallet is doing right now, so
/// the illustration and the checklist below it tell the same story.
class _IssuingHero extends StatefulWidget {
  const _IssuingHero({required this.step, required this.total});

  final int step;
  final int total;

  @override
  State<_IssuingHero> createState() => _IssuingHeroState();
}

class _IssuingHeroState extends State<_IssuingHero>
    with TickerProviderStateMixin {
  /// One icon per step, plus a final one for the beat between the last step
  /// and the issued credential appearing.
  static const List<IconData> _icons = [
    Icons.account_balance_rounded,
    Icons.how_to_reg_rounded,
    Icons.vpn_key_rounded,
    Icons.draw_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.badge_rounded,
  ];

  /// Breathing halo. Progress alone would look frozen inside a step — this is
  /// what keeps the screen alive between beats.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.step / widget.total).clamp(0.0, 1.0);
    final icon = _icons[widget.step.clamp(0, _icons.length - 1)];

    return SizedBox(
      height: 148,
      width: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => _Halo(t: _pulse.value),
          ),
          // The ring eases to each new value rather than jumping, so a step
          // completing reads as motion the user can follow.
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                size: const Size.square(148),
                painter: _ProgressRingPainter(
                  progress: value,
                  pulse: _pulse.value,
                ),
              ),
            ),
          ),
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: AppColors.raisedShadow,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 38,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final size = 118 + 12 * t;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.05 + 0.04 * (1 - t)),
      ),
    );
  }
}

/// Track, filled arc, and a pulsing head dot that marks where the work is.
class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress, required this.pulse});

  final double progress;
  final double pulse;

  static const double _stroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - _stroke / 2;
    final rect = Rect.fromCircle(center: centre, radius: radius);

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.surfaceSunken,
    );

    if (progress <= 0) return;

    // Starts at twelve o'clock so "done" reads as a full clock face.
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ).createShader(rect),
    );

    final head = centre +
        Offset(math.cos(start + sweep), math.sin(start + sweep)) * radius;
    canvas
      ..drawCircle(
        head,
        _stroke + 3 * pulse,
        Paint()..color = AppColors.primary.withValues(alpha: 0.22),
      )
      ..drawCircle(head, _stroke * 0.9, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.pulse != pulse;
}
