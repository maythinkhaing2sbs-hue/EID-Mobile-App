import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 5, stage 2 — offer biometric unlock.
///
/// Framed as an accelerator, never as a requirement: the PIN keeps working, and
/// "Not now" is a real, equally reachable choice. A national ID app that
/// pressures people into handing over a fingerprint loses trust it cannot buy
/// back.
class BiometricsScreen extends StatelessWidget {
  const BiometricsScreen({super.key});

  void _finish(BuildContext context, {required bool enabled}) {
    WalletScope.read(context).setBiometrics(enabled);
    Navigator.of(context).pushReplacementNamed(Routes.walletReady);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    // Face ID on iOS, fingerprint elsewhere — the icon should match the sensor
    // the user actually has.
    final bool faceFirst = Theme.of(context).platform == TargetPlatform.iOS;

    return AppScaffold(
      showBack: false,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: s.bioEnable,
            onPressed: () => _finish(context, enabled: true),
          ),
          Gap.h4,
          TextButton(
            onPressed: () => _finish(context, enabled: false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(s.bioSkip),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 132,
            width: 132,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              faceFirst ? Icons.face_rounded : Icons.fingerprint_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          Gap.h16,
          Text(
            s.bioFaceTouch,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Gap.h32,
          ScreenHeader(
            title: s.bioTitle,
            subtitle: s.bioSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          InfoNote(
            text: s.keyPointPrivate,
            icon: Icons.phonelink_lock_outlined,
          ),
        ],
      ),
    );
  }
}
