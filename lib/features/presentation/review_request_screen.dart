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
/// The claims are printed with the values that would be sent, exactly as the
/// issuance screen prints them. A checklist of field names tells the holder
/// which boxes the verifier ticked; it does not tell them what is about to
/// leave the device.
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
      title: s.reviewTitle,
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
                  for (final (i, claim) in request.requestedClaims.indexed)
                    ClaimValueRow(
                      label: claim.label(s),
                      value: preview.claims[claim] ?? '-',
                      tabular: claim.isTabular,
                      first: i == 0,
                    ),
                ] else
                  for (final claim in request.requestedClaims)
                    ClaimRow(label: claim.label(s)),
                Gap.h8,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _showDetails(context),
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

  void _showDetails(BuildContext context) {
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, Gap.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.viewDetails,
                  style: Theme.of(context).textTheme.titleLarge),
              Gap.h16,
              KeyValueRow(label: s.requestFrom, value: request.verifierName),
              const Divider(height: Gap.lg),
              KeyValueRow(
                label: 'response_uri',
                value: 'https://${request.verifierDomain}/oid4vp/response',
                numericValue: true,
              ),
              const Divider(height: Gap.lg),
              KeyValueRow(
                label: 'Protocol',
                value: request.isProximity
                    ? 'ISO 18013-5 (proximity)'
                    : 'OpenID4VP over HTTPS',
              ),
              const Divider(height: Gap.lg),
              KeyValueRow(
                label: s.verificationStatus,
                value: '${request.requestedClaims.length}',
                numericValue: true,
              ),
            ],
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
