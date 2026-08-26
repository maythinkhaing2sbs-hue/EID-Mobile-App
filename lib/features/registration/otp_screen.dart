import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
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
/// The number is set in the tabular face and given its own line, so it can be
/// checked digit by digit; "Change" sits directly under it as plain text,
/// because a mistyped digit is the commonest way this screen dead-ends and a
/// back arrow does not read as "fix the number".
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
      totalSteps: 3,
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
                        style: AppTypography.numeric(
                          size: 15,
                          weight: FontWeight.w600,
                          spacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  ),
                  child: Text(s.change),
                ),
              ],
            ),
          ),

          Gap.h16,
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
