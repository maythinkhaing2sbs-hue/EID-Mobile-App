import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 9 — request the credential (OpenID4VCI).
///
/// The screen answers three questions before the user commits: what credential,
/// from which issuer, and exactly which claims — *with their values* — it will
/// contain. Showing the values rather than a checklist of field names is the
/// point: consent to "Date of Birth" is not informed consent; consent to
/// "Date of Birth — 1990-05-15" is, and this is the last moment the holder can
/// spot a wrong record before the issuer signs it.
///
/// If the holder key does not exist yet, the primary action routes to key
/// creation first rather than failing later inside the issuance round-trip.
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

  /// Codes, numbers and ISO dates get the tabular face so they line up in a
  /// column; names and free text stay in the body face.
  static const Set<ClaimId> _tabular = {
    ClaimId.dateOfBirth,
    ClaimId.nationality,
    ClaimId.documentNumber,
    ClaimId.expiryDate,
  };

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
                        trailing: _FormatChip(label: credential.format),
                      ),
                      for (final claim in _claims)
                        _ClaimValueRow(
                          label: claim.label(s),
                          value: credential.claims[claim] ?? '-',
                          tabular: _tabular.contains(claim),
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

          Gap.h16,
          _HolderKeyCard(holderKey: wallet.holderKey),

          Gap.h16,
          InfoNote(text: s.keyPointBinding, icon: Icons.link_rounded),
        ],
      ),
    );
  }
}

/// Issuer identity, given the top slab of the card so "who is signing this?"
/// is answered before any of the data below it.
class _IssuerHeader extends StatelessWidget {
  const _IssuerHeader({required this.credential});

  final WalletCredential credential;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(Gap.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(credential.kind.label(s), style: text.titleMedium),
                Gap.h4,
                Text(credential.issuerName(s), style: text.bodySmall),
                Gap.h12,
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    label: s.issuerVerified,
                    icon: Icons.verified_rounded,
                    tone: BadgeTone.info,
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

/// The credential format, set in the mono face — a technical fact, marked as
/// one, so it never competes with the issuer name beside it.
class _FormatChip extends StatelessWidget {
  const _FormatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: Radii.pill,
      ),
      child: Text(label, style: AppTypography.mono(size: 11)),
    );
  }
}

/// One claim: the field name on the left, the value that will actually be
/// signed on the right. Hairline-separated rather than boxed — five bordered
/// tiles read as five separate objects, and this is one record.
class _ClaimValueRow extends StatelessWidget {
  const _ClaimValueRow({
    required this.label,
    required this.value,
    required this.tabular,
    required this.first,
  });

  final String label;
  final String value;
  final bool tabular;

  /// The first row sits directly under the section label and needs no rule
  /// above it.
  final bool first;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        if (!first)
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle_rounded,
                    size: 16, color: AppColors.success),
              ),
              Gap.w8,
              Expanded(
                flex: 4,
                child: Text(label, style: text.bodySmall),
              ),
              Gap.w12,
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: tabular
                      ? AppTypography.numeric(size: 14, weight: FontWeight.w600)
                      : text.titleSmall
                          ?.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Holder-key readiness. The credential cannot be bound without it, so the row
/// names the algorithm once the key exists and says what to do when it does
/// not — the primary button changes to match.
class _HolderKeyCard extends StatelessWidget {
  const _HolderKeyCard({required this.holderKey});

  final HolderKey? holderKey;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;
    final ready = holderKey != null;

    return AppCard(
      padding:
          const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color:
                  ready ? AppColors.successSurface : AppColors.warningSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ready ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 18,
              color: ready ? AppColors.success : AppColors.warning,
            ),
          ),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.holderKey, style: text.titleMedium),
                Gap.h4,
                Text(
                  ready ? holderKey!.algorithm : s.keyRequiredFirst,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          Gap.w8,
          StatusBadge(
            label: ready ? s.keyActive : s.keyStatusNotCreated,
            tone: ready ? BadgeTone.success : BadgeTone.warning,
          ),
        ],
      ),
    );
  }
}
