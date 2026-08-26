import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/eid_logo.dart';
import '../../widgets/language_toggle.dart';

/// Screen 1 — Welcome.
///
/// The language toggle is the first thing in the top-right, above the fold and
/// outside any card: a citizen who opens the app in the wrong language must be
/// able to fix that before reading anything else.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Padding(
          padding: Insets.page,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(top: Gap.sm),
                  child: LanguageToggle(),
                ),
              ),

              // The hero card. One card, generous whitespace — the whole screen
              // asks a single question, so nothing else competes with it.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Gap.xl,
                        vertical: Gap.xxxl,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: Radii.cardAll,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        children: [
                          const EidLogo(size: 88),
                          Gap.h32,
                          Text(
                            s.welcomeTitle,
                            style: text.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                          Gap.h12,
                          Text(
                            s.welcomeSubtitle,
                            style: text.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              PrimaryButton(
                label: s.createWallet,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.registerMethod),
              ),
              Gap.h12,
              SecondaryButton(
                label: s.signInExisting,
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.unlock),
              ),
              Gap.h24,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 14, color: AppColors.textTertiary),
                  Gap.w4,
                  Flexible(
                    child: Text(
                      s.issuedByGovernment,
                      style: text.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              Gap.h16,
            ],
          ),
        ),
      ),
    );
  }
}
