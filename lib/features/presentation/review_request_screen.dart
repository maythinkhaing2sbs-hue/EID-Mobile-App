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
import '../../widgets/verifier_logo.dart';

/// Screen 11 - review the verifier's request.
///
/// This is the first of three consent gates and the most important one: the
/// user learns *who* is asking before they learn what is being asked for. The
/// verifier's identity therefore gets the brand panel at the top of the screen,
/// carries its own logo and the trust badge, and shows the domain the response
/// will actually be posted to.
///
/// The claims are named, not printed with their values. This is the first of
/// the three gates and nothing has been agreed yet — putting the holder's date
/// of birth and document number on screen to describe a request that may be
/// declined shows the record to anyone glancing at the handset for no decision
/// it helps make. The values appear at the last gate, on the confirm-and-share
/// screen, where they are what is actually being sent.
class ReviewRequestScreen extends StatelessWidget {
  const ReviewRequestScreen({super.key, required this.request});

  final PresentationRequest request;

  /// The credential the previewed values are read from: the first one in the
  /// wallet that can satisfy the whole request, which is also the one the next
  /// screen preselects. Null while the wallet is empty - then the screen falls
  /// back to naming the claims, because inventing values would be worse than
  /// showing none.
  WalletCredential? _previewSource(List<WalletCredential> all) {
    for (final c in all) {
      if (request.requestedClaims.every(c.claims.containsKey)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;
    final preview = _previewSource(WalletScope.of(context).credentials);

    return AppScaffold(
      title: s.verifyWith(request.verifierName),
      bottomBar: ActionPair(
        secondary: DeclineButton(
          label: s.decline,
          onPressed: () => Navigator.of(context)
              .popUntil((route) => route.settings.name == Routes.home),
        ),
        primary: PrimaryButton(
          label: s.continueLabel,
          onPressed: () => Navigator.of(context).pushNamed(
            Routes.presentSelect,
            arguments: request,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          _RequesterCard(request: request),

          Gap.h16,
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(s.theyRequest),
                if (preview != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded,
                          size: 14, color: AppColors.primary),
                      Gap.w4,
                      Flexible(
                        child: Text(
                          preview.kind.label(s),
                          style: text.labelMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap.h4,
                ],
                for (final claim in request.requestedClaims)
                  ClaimRow(label: claim.label(s)),
                Gap.h8,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _showDetails(context, preview),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(s.viewDetails),
                  ),
                ),
              ],
            ),
          ),

          Gap.h16,
          InfoNote(text: s.sentSecurely, icon: Icons.https_outlined),
        ],
      ),
    );
  }

  /// The fields the sheet lists, in ID-card order. Address is on the list
  /// although no verifier on this screen asks for it: the sheet answers "what
  /// does this document carry?", not "what is being sent?" - that question is
  /// already answered by the card behind it.
  static const List<ClaimId> _detailClaims = [
    ClaimId.fullName,
    ClaimId.myanmarName,
    ClaimId.fatherName,
    ClaimId.dateOfBirth,
    ClaimId.gender,
    ClaimId.bloodType,
    ClaimId.nationality,
    ClaimId.documentNumber,
    ClaimId.expiryDate,
    ClaimId.address,
  ];

  /// The full record behind the request.
  ///
  /// The endpoint URL and protocol name that used to sit here were the two
  /// facts on the screen no holder can act on - a `response_uri` tells someone
  /// deciding whether to hand over their ID exactly nothing. What they can act
  /// on is the document itself, so that is what the sheet shows.
  void _showDetails(BuildContext context, WalletCredential? preview) {
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      // Capped rather than free-standing: the record is long enough to fill the
      // screen, and a sheet that reaches the status bar stops reading as a
      // sheet - the request behind it has to stay visible for the holder to
      // know what they are still deciding about.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, Gap.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.viewDetails,
                    style: Theme.of(context).textTheme.titleLarge),
                Gap.h16,
                KeyValueRow(label: s.requestFrom, value: request.verifierName),
                const Divider(height: Gap.lg),
                if (preview case final credential?) ...[
                  // Field names only. The values behind them are the holder's
                  // record, and this sheet is read before any decision to share
                  // has been made — printing them here would put the whole
                  // document on screen to answer a question about which fields
                  // it holds.
                  for (final claim in _detailClaims)
                    if (credential.claims.containsKey(claim)) ...[
                      ClaimRow(label: claim.label(s), checked: false),
                      const Divider(height: Gap.lg),
                    ],
                  KeyValueRow(
                    label: s.issuer,
                    value: credential.issuerName(s),
                  ),
                ] else
                  KeyValueRow(
                    label: s.theyRequest,
                    value: '${request.requestedClaims.length}',
                    numericValue: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Who is asking, painted in the brand gradient.
///
/// The old version of this card was white on white and read as one more row of
/// text; the single most consequential fact on the screen looked like the least
/// important. Giving it the panel puts the requester's logo, name and domain on
/// the one surface the user cannot skim past.
class _RequesterCard extends StatelessWidget {
  const _RequesterCard({required this.request});

  final PresentationRequest request;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return BrandPanel(
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.requestFrom,
            style: text.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Gap.h12,
          Row(
            children: [
              VerifierLogo(name: request.verifierName, size: 56),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.verifierName,
                      style: text.titleLarge
                          ?.copyWith(color: AppColors.textOnPrimary),
                    ),
                    Gap.h4,
                    Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8)),
                        Gap.w4,
                        Flexible(
                          child: Text(
                            request.verifierDomain,
                            style: text.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.trusted) ...[
            Gap.h16,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GlassBadge(
                label: s.verifierVerified,
                icon: Icons.verified_rounded,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
