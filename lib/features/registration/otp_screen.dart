import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/icon_motion.dart';
import '../../widgets/otp_field.dart';
import '../../widgets/pulse_icon.dart';

/// Step 2 — verify the one-time code.
///
/// Deliberately spare: an icon, a heading, the destination, six boxes. Every
/// container that was here before — the chip around the number, the card around
/// the resend — was chrome drawn around content that already read fine on its
/// own, and it crowded a screen the user needs to scan in one glance while
/// holding an SMS in their other hand.
///
/// The destination is masked and given its own line so it can be checked at a
/// glance. There is no "change it" affordance: the address was typed two
/// screens ago and the back arrow already walks there, so a second route out
/// only added a way to lose a code that has already been sent.
///
/// Demo rule: any 6 digits verify, except `000000`, which is wired to the
/// failure path so the error state stays reachable during review.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpKey = GlobalKey<OtpFieldState>();
  String _code = '';
  String? _error;
  bool _busy = false;

  Future<void> _verify() async {
    if (_code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    if (_code == '000000') {
      setState(() {
        _busy = false;
        _error = AppStrings.of(context).errOtp;
      });
      _otpKey.currentState?.clear();
      return;
    }

    setState(() => _busy = false);
    Navigator.of(context).pushNamed(Routes.securityPin);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;
    final draft = WalletScope.of(context).draft;
    final byEmail = draft.method == RegistrationMethod.email;

    return AppScaffold(
      step: 2,
      totalSteps: 4,
      bottomBar: PrimaryButton(
        label: s.verify,
        busy: _busy,
        onPressed: _code.length == 6 ? _verify : null,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          Center(
            child: PulseIcon(
              icon: byEmail
                  ? Icons.mark_email_unread_rounded
                  : Icons.sms_rounded,
              // Tinted like the PIN badge rather than a solid brand disc: the
              // two screens are consecutive, and the heavier mark made this
              // one read as the more important of the pair.
              fill: AppColors.secondary,
              iconColor: AppColors.primary,
              // The glyph keeps landing for as long as the code has not.
              motion: IconMotion.arrive,
            ),
          ),

          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Column(
              children: [
                Text(
                  byEmail ? s.otpTitleEmail : s.otpTitle,
                  style: text.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                Gap.h12,

                // Lead-in and number on one centred line: the label is context,
                // the number is the fact being checked, so only the number
                // takes weight.
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${s.otpSentTo} ', style: text.bodyMedium),
                      TextSpan(
                        text: draft.otpTarget,
                        // A masked address is read as a word; only a number
                        // earns the tabular face.
                        style: byEmail
                            ? text.bodyLarge?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              )
                            : AppTypography.numeric(
                                size: 15,
                                weight: FontWeight.w600,
                                spacing: 0.4,
                              ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Gap.h24,
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: OtpField(
              key: _otpKey,
              errorText: _error,
              onChanged: (v) => setState(() {
                _code = v;
                if (_error != null) _error = null;
              }),
              onCompleted: (_) => _verify(),
            ),
          ),

          Gap.h24,
          Center(
            child: ResendTimer(
              seconds: 45,
              waitingLabel: s.resendIn,
              resendLabel: s.resendCode,
              onResend: () {
                _otpKey.currentState?.clear();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(s.resendCode)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
