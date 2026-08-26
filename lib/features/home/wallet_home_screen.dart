import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/eid_logo.dart';
import '../../widgets/language_toggle.dart';

/// Wallet home — the hub the 15 designed flows return to.
///
/// Not one of the numbered screens, but every one of them either starts or ends
/// here, so it has to exist for the flow to be walkable end to end.
class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, Gap.sm, 20, Gap.xxxl),
          children: [
            Row(
              children: [
                const EidLogo(size: 34),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.homeGreeting, style: text.bodySmall),
                      Text(
                        wallet.displayName,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const LanguageToggle(compact: true),
              ],
            ),

            Gap.h32,
            SectionLabel(s.myCredentials),

            if (wallet.credentials.isEmpty)
              _EmptyCredentials(
                onAdd: () =>
                    Navigator.of(context).pushNamed(Routes.credentialRequest),
              )
            else
              for (final c in wallet.credentials) ...[
                CredentialCard(credential: c, compact: false),
                Gap.h12,
              ],

            Gap.h24,
            SectionLabel(s.quickActions),
            _Action(
              icon: Icons.qr_code_scanner_rounded,
              label: s.actionScan,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.presentScan),
            ),
            Gap.h8,
            _Action(
              icon: Icons.add_card_rounded,
              label: s.actionAdd,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.credentialRequest),
            ),
            Gap.h8,
            _Action(
              icon: Icons.shield_outlined,
              label: s.actionSecurity,
              trailing: StatusBadge(
                label: wallet.hasHolderKey
                    ? s.keyActive
                    : s.keyStatusNotCreated,
                tone: wallet.hasHolderKey
                    ? BadgeTone.success
                    : BadgeTone.warning,
              ),
              onTap: () => Navigator.of(context).pushNamed(
                wallet.hasHolderKey ? Routes.keyCreated : Routes.keyCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCredentials extends StatelessWidget {
  const _EmptyCredentials({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AppCard(
      padding: Insets.cardLoose,
      onTap: onAdd,
      child: Column(
        children: [
          const Icon(Icons.add_card_outlined,
              size: 36, color: AppColors.textTertiary),
          Gap.h12,
          Text(
            s.noCredentials,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          Gap.h8,
          Text(
            s.getYourIdTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg, vertical: Gap.md),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              borderRadius: Radii.fieldAll,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          Gap.w12,
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (trailing != null) ...[trailing!, Gap.w8],
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
