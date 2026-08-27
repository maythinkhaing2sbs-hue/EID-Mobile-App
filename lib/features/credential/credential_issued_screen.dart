import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/success_check.dart';

/// Screen 8d — "Credential Issued": the credential itself, front and centre.
///
/// This is the *end* of the wait, not the end of the request. The holder
/// reaches it days after submitting, when the issuer's approval lands — see
/// [CredentialPendingScreen], which is where the flow itself stops. Keeping the
/// two apart is what lets each say something true: one is a receipt for an
/// application, this one is a signed government document.
class CredentialIssuedScreen extends StatelessWidget {
  const CredentialIssuedScreen({super.key, this.credential});

  /// The credential that just arrived. Left null when the screen is opened
  /// without one — it then shows whatever National ID the wallet holds.
  final WalletCredential? credential;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final shown = credential ?? _fromWallet(context);

    return AppScaffold(
      showBack: false,
      bottomBar: PrimaryButton(
        label: s.goToWalletHome,
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.home, (route) => false),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.xl),
        children: [
          const Center(child: SuccessCheck(size: 80)),
          Gap.h24,
          ScreenHeader(
            title: s.credentialIssued,
            subtitle: s.credentialIssuedSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          CredentialCard(credential: shown),
          Gap.h16,
          AppCard(
            child: Column(
              children: [
                KeyValueRow(
                  label: s.issuer,
                  value: shown.issuerName(s),
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.attrExpiry,
                  value: shown.validUntil,
                  numericValue: true,
                ),
              ],
            ),
          ),
          Gap.h16,
          InfoNote(text: s.keyPointBinding, icon: Icons.link_rounded),
        ],
      ),
    );
  }

  /// The National ID the wallet holds, falling back to the sample record so the
  /// screen renders standalone in a preview frame rather than crashing on an
  /// empty wallet.
  WalletCredential _fromWallet(BuildContext context) {
    final held = WalletScope.of(context).credentials;
    return held.firstWhere(
      (c) => c.kind == CredentialKind.nationalId,
      orElse: () => held.isEmpty
          ? WalletCredential.sampleNationalId
          : held.first,
    );
  }
}
