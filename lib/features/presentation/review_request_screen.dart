import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 11 — review the verifier's request.
///
/// This is the first of three consent gates and the most important one: the
/// user learns *who* is asking before they learn what is being asked for. The
/// verifier's identity therefore sits above the claim list, carries the trust
/// badge, and shows the domain the response will actually be posted to.
class ReviewRequestScreen extends StatelessWidget {
  const ReviewRequestScreen({super.key, required this.request});

  final PresentationRequest request;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

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
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.requestFrom, style: text.bodySmall),
                Gap.h12,
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
                          Text(request.verifierName, style: text.titleLarge),
                          Gap.h4,
                          Text(request.verifierDomain, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                if (request.trusted) ...[
                  Gap.h16,
                  StatusBadge(
                    label: s.verifierVerified,
                    icon: Icons.verified_rounded,
                  ),
                ],
              ],
            ),
          ),

          Gap.h16,
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(s.theyRequest),
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
