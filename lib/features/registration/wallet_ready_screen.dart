import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/success_check.dart';

/// Screen 6 — registration complete.
///
/// A full-screen moment with exactly one action. No back affordance: the
/// registration stack is discarded here, so the user cannot walk backwards into
/// a half-finished sign-up.
class WalletReadyScreen extends StatelessWidget {
  const WalletReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      showBack: false,
      bottomBar: PrimaryButton(
        label: s.goToWalletHome,
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.home, (route) => false),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Gap.xxxl),
        child: SuccessLayout(
          title: s.readyTitle,
          subtitle: s.readySubtitle,
        ),
      ),
    );
  }
}
