import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/otp_field.dart';

/// Screen 4 — verify the one-time code.
///
/// Demo rule: any 6 digits verify, except `000000`, which is wired to the
/// failure path so the error state is reachable during review.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpKey = GlobalKey<State<OtpField>>();
  String _code = '';
  String? _error;
  bool _busy = false;

  Future<void> _verify() async {
    if (_code.length != 6) return;
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
      return;
    }

    setState(() => _busy = false);
    Navigator.of(context).pushNamed(Routes.securityPin);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final draft = WalletScope.of(context).draft;

    return AppScaffold(
      step: 3,
      totalSteps: 4,
      bottomBar: PrimaryButton(
        label: s.verify,
        busy: _busy,
        onPressed: _code.length == 6 ? _verify : null,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          // A single illustration anchors the screen. Kept as an icon in a
          // tinted disc rather than a stock illustration — it renders at any
          // density and never looks like clip art.
          Center(
            child: Container(
              height: 88,
              width: 88,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  size: 40, color: AppColors.primary),
            ),
          ),
          Gap.h32,
          ScreenHeader(
            title: s.otpTitle,
            subtitle: s.otpSubtitle(draft.otpTarget),
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          OtpField(
            key: _otpKey,
            errorText: _error,
            onChanged: (v) => setState(() {
              _code = v;
              if (_error != null) _error = null;
            }),
            onCompleted: (_) => _verify(),
          ),
          Gap.h24,
          Center(
            child: ResendTimer(
              seconds: 45,
              waitingLabel: s.resendIn,
              resendLabel: s.resendCode,
              onResend: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.resendCode)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
