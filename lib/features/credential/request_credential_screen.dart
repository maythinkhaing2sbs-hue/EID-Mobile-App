import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/brand_panel.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 9 - request the credential (OpenID4VCI).
///
/// The screen answers three questions before the user commits: what credential,
/// from which issuer, and exactly which claims - with their values - it will
/// contain. Showing the values rather than a checklist of field names is the
/// point: consent to "Date of Birth" is not informed consent; consent to
/// "Date of Birth - 1990-05-15" is, and this is the last moment the holder can
/// spot a wrong record before the issuer signs it.
///
/// If the holder key does not exist yet, the primary action routes to key
/// creation first rather than failing later inside the issuance round-trip.
class RequestCredentialScreen extends StatelessWidget {
  const RequestCredentialScreen({super.key});

  /// Render order for the claim list. Fixed here rather than taken from the
  /// claim map so the list always reads like a physical ID card, whatever
  /// order the issuer happens to return.
  ///
  /// Field names only, and no expiry date: nothing has been issued yet, so
  /// every value printed here would be a value the wallet made up about a
  /// document that does not exist. What the holder can be told at this point is
  /// which fields the credential will carry.
  static const List<ClaimId> _claims = [
    ClaimId.fullName,
    ClaimId.dateOfBirth,
    ClaimId.nationality,
    ClaimId.documentNumber,
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    final credential = wallet.pendingNationalId;

    return AppScaffold(
      title: s.credential,
      bottomBar: PrimaryButton(
        label: wallet.hasHolderKey ? s.requestCredential : s.createKeyPair,
        icon:
            wallet.hasHolderKey ? Icons.download_rounded : Icons.vpn_key_rounded,
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
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IssuerHeader(credential: credential),
                const Divider(
                    height: 1, thickness: 1, color: AppColors.divider),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.xl, Gap.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(s.whatYouGet),
                      for (final claim in _claims)
                        ClaimRow(label: claim.label(s)),
                      Gap.h12,
                      Text(
                        s.whatYouGetHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Only shown once the key exists, as a confirmation. A card that
          // announces a missing key would be raising an alarm the user cannot
          // act on from here - the primary button already changes to
          // "Create Holder Key Pair" and takes them to the one screen that
          // fixes it.
          if (wallet.holderKey case final key?) ...[
            Gap.h16,
            HolderKeyCard(holderKey: key),
          ],

          Gap.h16,
          InfoNote(text: s.keyPointBinding, icon: Icons.link_rounded),
        ],
      ),
    );
  }
}

/// Issuer identity, given the top slab of the card so "who is signing this?"
/// is answered before any of the data below it.
///
/// Painted in the brand gradient rather than left white: this is the one object
/// on screen that will become a government ID, and the header is the preview
/// of it.
class IssuerHeader extends StatelessWidget {
  const IssuerHeader({super.key, required this.credential});

  final WalletCredential credential;

  /// The document, not the ministry behind it: the issuer is already named on
  /// the line below, so a building here would say the same thing twice and
  /// leave the card itself unillustrated.
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return BrandPanel(
      borderRadius: const BorderRadius.vertical(top: Radii.card),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: Radii.fieldAll,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(credential.kind.icon,
                color: AppColors.textOnPrimary),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.kind.label(s),
                  style:
                      text.titleMedium?.copyWith(color: AppColors.textOnPrimary),
                ),
                Gap.h4,
                Text(
                  credential.issuerName(s),
                  style: text.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
                Gap.h12,
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassBadge(
                    label: s.issuerVerified,
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// The holder key, once it exists - a quiet confirmation that the credential
/// has something to bind to. The screen omits this card entirely while the key
/// is missing rather than showing a warning: the state is expected at this
/// point in the flow, and the primary button is already the way out of it.
class HolderKeyCard extends StatelessWidget {
  const HolderKeyCard({super.key, required this.holderKey});

  final HolderKey holderKey;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding:
          const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: AppColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 18, color: AppColors.success),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.holderKey, style: text.titleMedium),
                Gap.h4,
                Text(holderKey.algorithm, style: text.bodySmall),
              ],
            ),
          ),
          Gap.w8,
          StatusBadge(label: s.keyActive),
        ],
      ),
    );
  }
}
