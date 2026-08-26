import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/pin_pad.dart';

/// Screen 5, stage 1 — set and confirm the wallet PIN.
///
/// Both stages live in one screen and swap in place. Pushing a second route for
/// the confirmation would let the user press Back into a half-set PIN; here,
/// Back from the confirm stage simply returns to entry with the first PIN
/// cleared, which is the only sane recovery.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pin = PinController();
  String? _first;

  @override
  void initState() {
    super.initState();
    _pin.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _pin.removeListener(_onPinChanged);
    _pin.dispose();
    super.dispose();
  }

  bool get _confirming => _first != null;

  void _onPinChanged() {
    setState(() {});
    if (!_pin.isComplete) return;

    // Give the last dot a beat to land before the stage changes.
    final entered = _pin.value;
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      if (!_confirming) {
        setState(() => _first = entered);
        _pin.clear();
      } else if (entered == _first) {
        WalletScope.read(context).setPin(entered);
        Navigator.of(context).pushReplacementNamed(Routes.securityBiometrics);
      } else {
        _pin.fail();
      }
    });
  }

  void _back() {
    if (_confirming) {
      setState(() => _first = null);
      _pin.clear();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      step: 4,
      totalSteps: 4,
      onBack: _back,
      child: Column(
        children: [
          Gap.h24,
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 32, color: AppColors.primary),
          ),
          Gap.h24,
          ScreenHeader(
            title: _confirming ? s.pinConfirmTitle : s.pinTitle,
            subtitle: _confirming ? s.pinConfirmSubtitle : s.pinSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          ShakeOnError(
            trigger: _pin.errorTrigger,
            child: PinDots(filled: _pin.filled, error: _pin.hasError),
          ),
          SizedBox(
            height: 28,
            child: Center(
              child: _pin.hasError
                  ? Text(
                      s.errPinMismatch,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.danger),
                    )
                  : null,
            ),
          ),
          const Spacer(),
          NumericKeypad(
            onDigit: _pin.push,
            onBackspace: _pin.backspace,
          ),
          Gap.h16,
        ],
      ),
    );
  }
}
