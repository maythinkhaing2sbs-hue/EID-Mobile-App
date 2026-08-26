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
                Text.rich(
                  _titleSpan(s.welcomeTitle, s.welcomeTitleAccent),
                  // Looser leading than the shared display style: this is
                  // the only two-line headline in the app, and Myanmar sets
                  // marks above and below the baseline that collide at the
                  // tighter tracking body copy can afford.
                  style: text.displayLarge?.copyWith(height: 1.52),
                  textAlign: TextAlign.start,
                ),

                const Spacer(flex: 3),

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
                Gap.h16,

                // Provenance sits under the action, not above it. It is a
                // footnote about who stands behind the app — worth saying,
                // but not worth putting between the user and the one thing
                // this screen asks them to do.
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
                Gap.h24,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The welcome headline with the product's name lifted into brand blue.
///
/// The run to tint comes from the string table rather than being hard-coded
/// here: it opens the Myanmar sentence and sits mid-sentence in the English
/// one, so a lookup keeps both locales on one code path. Copy that leaves the
/// two out of step degrades to a plain, untinted title rather than throwing.
TextSpan _titleSpan(String title, String accent) {
  final start = accent.isEmpty ? -1 : title.indexOf(accent);
  if (start < 0) return TextSpan(text: title);

  final end = start + accent.length;
  return TextSpan(
    children: [
      if (start > 0) TextSpan(text: title.substring(0, start)),
      TextSpan(
        text: accent,
        style: const TextStyle(color: AppColors.primary),
      ),
      if (end < title.length) TextSpan(text: title.substring(end)),
    ],
  );
}
