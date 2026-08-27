import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/pulse_icon.dart';
import '../../widgets/success_check.dart';

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
        label: s.goToKeyPair,
        icon: Icons.arrow_forward_rounded,
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.keyCreate, (route) => false),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.xxl, bottom: Gap.xl),
        children: [
          // The tick the rest of the app uses for "this completed", at hero
          // size and still beating: registration is done, and the mark says so
          // for as long as the user is on the screen rather than for the first
          // half second of it.
          const Center(child: SuccessCheck(size: 112)),
          Gap.h32,
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: Column(
              children: [
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
              ],
            ),
          ),
          Gap.h32,

          // A checklist rather than a paragraph: the two things registration
          // just put behind the user, named so the progress is concrete.
          FadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: AppCard(
              padding: Insets.cardLoose,
              child: Column(
                children: [
                  _DoneRow(label: s.readyStepEmail),
                  const Divider(height: Gap.xl),
                  _DoneRow(label: s.readyStepPin),
                ],
              ),
            ),
          ),
        ],
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
