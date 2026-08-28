import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import 'request_credential_screen.dart';

/// "View credential" — the credential the wallet already holds, opened from
/// Wallet Home rather than from the issuance flow.
///
/// It is the request screen's page with two deliberate differences, and both
/// follow from the document existing:
///  * the claims are printed **with their values**. On the request screen a
///    value would be a guess about a document that has not been signed; here it
///    is the record itself, and the holder's own copy of it is the whole point
///    of opening the screen.
///  * there is no action at the bottom. Nothing is being requested — this is a
///    reference view, and a "Request Credential" button on a credential already
///    held would file a second application.
///
/// Home routes here only once the National ID is in the wallet. While a request
/// is still open it sends the user to the pending screen instead, and while
/// there is neither it sends them into the issuance flow.
class CredentialDetailScreen extends StatelessWidget {
  const CredentialDetailScreen({super.key, this.credential});

  /// The credential to show. Falls back to the National ID the wallet holds,
  /// so the route works without an argument.
  final WalletCredential? credential;

  /// ID-card order, as on the request screen. The expiry date is on the list
  /// here although it is not on that one: this document has a real one, and it
  /// is the field a holder most often opens their ID to check.
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
    final shown = credential ?? _fromWallet(wallet);

    return AppScaffold(
      title: s.credential,
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.yourDigitalIdTitle,
            subtitle: s.yourDigitalIdSubtitle,
          ),
          Gap.h24,

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IssuerHeader(credential: shown),
                const Divider(
                    height: 1, thickness: 1, color: AppColors.divider),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(Gap.xl, Gap.lg, Gap.xl, Gap.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(
                        s.credentialContains,
                        trailing: FormatChip(label: shown.format),
                      ),
                      for (final claim in _claims)
                        if (shown.claims[claim] case final value?)
                          ClaimValueRow(
                            label: claim.label(s),
                            value: value,
                            tabular: claim.isTabular,
                            first: claim == _claims.first,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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

  /// The National ID the wallet holds, falling back to the sample record so the
  /// screen renders standalone in a preview frame rather than crashing on an
  /// empty wallet.
  WalletCredential _fromWallet(WalletState wallet) {
    final held = wallet.credentials;
    return held.firstWhere(
      (c) => c.kind == CredentialKind.nationalId,
      orElse: () =>
          held.isEmpty ? WalletCredential.sampleNationalId : held.first,
    );
  }
}
