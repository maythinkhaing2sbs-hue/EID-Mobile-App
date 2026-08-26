import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 9 — request the credential (OpenID4VCI).
///
/// The screen answers three questions before the user commits: what credential,
/// from which issuer, and exactly which claims it will contain. If the holder
/// key does not exist yet, the primary action routes to key creation first
/// rather than failing later inside the issuance round-trip.
class RequestCredentialScreen extends StatelessWidget {
  const RequestCredentialScreen({super.key});

  static const List<ClaimId> _claims = [
    ClaimId.fullName,
    ClaimId.dateOfBirth,
    ClaimId.nationality,
    ClaimId.documentNumber,
    ClaimId.expiryDate,
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: s.credential,
      bottomBar: PrimaryButton(
        label: wallet.hasHolderKey ? s.requestCredential : s.createKeyPair,
        icon: wallet.hasHolderKey ? Icons.download_rounded : Icons.vpn_key_rounded,
        onPressed: () => Navigator.of(context).pushNamed(
          wallet.hasHolderKey ? Routes.credentialIssuing : Routes.keyCreate,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.getYourIdTitle,
            subtitle: s.getYourIdSubtitle,
          ),
          Gap.h24,

          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: Radii.fieldAll,
                      ),
                      child: const Icon(Icons.account_balance_rounded,
                          color: AppColors.primary),
                    ),
                    Gap.w12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.credNationalId, style: text.titleMedium),
                          Gap.h4,
                          Text(s.issuerMoha, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: Gap.xxl),
                SectionLabel(s.whatYouGet),
                for (final claim in _claims)
                  ClaimRow(label: claim.label(s)),
              ],
            ),
          ),

          Gap.h16,
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg, vertical: Gap.md),
            child: Row(
              children: [
                Icon(
                  wallet.hasHolderKey
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 20,
                  color: wallet.hasHolderKey
                      ? AppColors.success
                      : AppColors.warning,
                ),
                Gap.w12,
                Expanded(child: Text(s.holderKey, style: text.titleMedium)),
                StatusBadge(
                  label: wallet.hasHolderKey
                      ? s.keyActive
                      : s.keyStatusNotCreated,
                  tone: wallet.hasHolderKey
                      ? BadgeTone.success
                      : BadgeTone.warning,
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
}
