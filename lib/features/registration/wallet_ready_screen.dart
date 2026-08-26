import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Registration complete — and a hand-off, not an ending.
///
/// The checklist confirms what registration actually finished. What comes
/// next is carried by the subtitle and the single action, both of which name
/// key creation: the wallet cannot receive a credential until that key exists,
/// so the screen never lets the user believe they are done.
///
/// No back affordance: the registration stack is discarded, so the user cannot
/// walk backwards into a half-finished sign-up.
class WalletReadyScreen extends StatelessWidget {
  const WalletReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      showBack: false,
      bottomBar: PrimaryButton(
        label: s.secureWalletCta,
        icon: Icons.arrow_forward_rounded,
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.keyCreate, (route) => false),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.xxl, bottom: Gap.xl),
        children: [
          const Center(child: _WalletReadyHero()),
          Gap.h32,
          Text(
            s.readyTitle,
            style: text.headlineLarge,
            textAlign: TextAlign.center,
          ),
          Gap.h12,
          Text(
            s.readySubtitle,
            style: text.bodyMedium,
            textAlign: TextAlign.center,
          ),
          Gap.h32,

          // A checklist rather than a paragraph: the two things registration
          // just put behind the user, named so the progress is concrete.
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              children: [
                _DoneRow(label: s.readyStepPhone),
                const Divider(height: Gap.xl),
                _DoneRow(label: s.readyStepPin),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The milestone mark for this screen: the wallet itself, sealed.
///
/// A bare green tick is the same mark this app uses for a validated field, so
/// it reads as "that worked" rather than "you now have a wallet". Giving the
/// object its own gradient badge — brand blue, the colour reserved for the
/// credential card — and hanging the tick off it as a seal makes the moment
/// look like something was *issued to the user*, not merely accepted.
class _WalletReadyHero extends StatefulWidget {
  const _WalletReadyHero();

  @override
  State<_WalletReadyHero> createState() => _WalletReadyHeroState();
}

class _WalletReadyHeroState extends State<_WalletReadyHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  )..forward();

  /// Three beats: the rings breathe out, the wallet lands, the seal snaps on.
  /// Staging them is what separates a milestone from a static illustration.
  late final Animation<double> _rings = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _badge = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
  );

  late final Animation<double> _seal = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.5, 1, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => HapticFeedback.mediumImpact(),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      width: 164,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: _rings,
            child: const _Ring(size: 164, opacity: 0.06),
          ),
          ScaleTransition(
            scale: _rings,
            child: const _Ring(size: 130, opacity: 0.10),
          ),
          ScaleTransition(
            scale: _badge,
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                boxShadow: AppColors.raisedShadow,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 46,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          Positioned(
            right: 17,
            bottom: 17,
            child: ScaleTransition(
              scale: _seal,
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  // The white collar is what lifts the seal off the badge
                  // instead of letting green and blue smear together.
                  border: Border.all(color: AppColors.surface, width: 3),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 19,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: opacity),
      ),
    );
  }
}

/// One completed setup step.
class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 22, color: AppColors.success),
        Gap.w12,
        Expanded(
          child: Text(
            label,
            style: text.bodyLarge?.copyWith(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
