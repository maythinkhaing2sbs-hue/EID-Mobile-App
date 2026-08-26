import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/buttons.dart';
import '../../widgets/id_backdrop.dart';
import '../../widgets/language_toggle.dart';

/// Screen 1 — Welcome.
///
/// Three things and nothing else: the mark, the greeting, and one way forward.
/// No card and no supporting paragraph — a splash screen that explains the
/// product is a splash screen nobody reads, and the explaining is done by the
/// screens that follow.
///
/// Sign-in versus registration is asked one screen later, on the auth form,
/// where the segmented control makes the choice reversible.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IdBackdrop(
        child: SafeArea(
          child: Padding(
            padding: Insets.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // First in the reading order and outside everything else:
                // someone who opened the app in the wrong language must be able
                // to fix that before reading a word of it.
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: Gap.sm),
                    child: LanguageToggle(),
                  ),
                ),

                const Spacer(flex: 2),

                // Plated, not bare: the mark ships as a JPEG with a hard white
                // matte, which over the security pattern would otherwise read
                // as a stray white rectangle.
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppLogo(height: 82),
                ),
                Gap.h24,
                Text(
                  s.welcomeTitle,
                  style: text.displayLarge,
                  textAlign: TextAlign.start,
                ),

                const Spacer(flex: 3),

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

                // Centred and hugging its label rather than full-bleed: on a
                // screen with a single action there is nothing to line it up
                // with, and the pill reads as an invitation rather than a form
                // submit.
                Center(
                  child: PrimaryButton(
                    label: s.letsGetStarted,
                    compact: true,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.auth),
                  ),
                ),
                Gap.h24,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
