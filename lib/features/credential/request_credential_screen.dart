import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/brand_panel.dart';
import '../../widgets/cards.dart';

/// Screen 9 - the credential, in full (OpenID4VCI).
///
/// The screen answers three questions: what credential, from which issuer, and
/// exactly which claims - with their values - it carries. Showing the values
/// rather than a checklist of field names is the point: "Date of Birth" tells
/// the holder nothing they can check, while "Date of Birth - 1990-05-15" lets
/// them spot a wrong record in the document that bears their name.
///
/// Read-only. Nothing on this screen starts an issuance round-trip.
class RequestCredentialScreen extends StatelessWidget {
  const RequestCredentialScreen({super.key});

  /// Render order for the claim table. Fixed here rather than taken from the
  /// claim map so the table always reads like a physical ID card, whatever
  /// order the issuer happens to return.
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
    final credential = wallet.pendingNationalId;

    return AppScaffold(
      title: s.credential,
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.yourIdTitle,
            subtitle: s.yourIdSubtitle,
          ),
          Gap.h24,

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IssuerHeader(credential: credential),
                const Divider(
                    height: 1, thickness: 1, color: AppColors.divider),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.xl, Gap.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(
                        s.whatYouGet,
                        trailing: FormatChip(label: credential.format),
                      ),
                      for (final claim in _claims)
                        ClaimValueRow(
                          label: claim.label(s),
                          value: credential.claims[claim] ?? '-',
                          tabular: claim.isTabular,
                          first: claim == _claims.first,
                        ),
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
          // act on from here - this screen only reports what the wallet holds,
          // and the key is created in the wallet setup flow.
          if (wallet.holderKey case final key?) ...[
            Gap.h16,
            _HolderKeyCard(holderKey: key),
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
class _IssuerHeader extends StatelessWidget {
  const _IssuerHeader({required this.credential});

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
class _HolderKeyCard extends StatelessWidget {
  const _HolderKeyCard({required this.holderKey});

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
