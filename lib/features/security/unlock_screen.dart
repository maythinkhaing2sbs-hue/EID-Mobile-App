import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/eid_logo.dart';
import '../../widgets/pin_pad.dart';

/// "Sign In with Existing Wallet" — PIN (or biometric) unlock.
///
/// Reuses the same keypad and dot indicator as PIN setup so unlocking feels
/// like the same gesture the user rehearsed during registration.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pin = PinController();

  @override
  void initState() {
    super.initState();
    _pin.addListener(_onChanged);
    // A wallet that has never been registered on this device has nothing to
    // unlock; seed a demo session so the screen is reachable from Welcome.
    WalletScope.read(context).seedDemoCredentials();
  }

  @override
  void dispose() {
    _pin.removeListener(_onChanged);
    _pin.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (!_pin.isComplete) return;

    final wallet = WalletScope.read(context);
    final entered = _pin.value;

    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      // With no PIN registered on this device, any 6 digits open the demo
      // wallet; once one is set it must match.
      if (!wallet.isRegistered || wallet.verifyPin(entered)) {
        _unlock();
      } else {
        _pin.fail(PinError.mismatch);
      }
    });
  }

  void _unlock() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);

    return AppScaffold(
      child: Column(
        children: [
          Gap.h24,
          const EidLogo(size: 56),
          Gap.h24,
          ScreenHeader(
            title: s.appName,
            subtitle: s.pinSubtitle,
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
            onBiometric: wallet.biometricsEnabled ? _unlock : null,
            biometricIcon: Theme.of(context).platform == TargetPlatform.iOS
                ? Icons.face_rounded
                : Icons.fingerprint_rounded,
          ),
          Gap.h16,
        ],
      ),
    );
  }
}
