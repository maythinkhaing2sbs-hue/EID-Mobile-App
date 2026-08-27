import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cards.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/verifier_logo.dart';

/// Wallet home — the hub every flow returns to.
///
/// Credentials are the reason the app exists, so they get the whole width and a
/// swipeable deck rather than a stack of full-height slabs: two gradient cards
/// piled vertically pushed everything else below the fold and made neither of
/// them feel primary.
///
/// There is no Security row. The holder key is created during onboarding, so a
/// permanent "Security — Active" row is a status light for something the user
/// already finished and cannot usefully act on from here.
class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    final credentials = wallet.credentials;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xxxl),
          children: [
            Padding(
              padding: Insets.page,
              child: _Greeting(
                name: wallet.displayName,
                protected: wallet.hasHolderKey,
              ),
            ),

            Gap.h32,
            Padding(
              padding: Insets.page,
              child: SectionLabel(
                s.myCredentials,
                trailing: credentials.isEmpty
                    ? null
                    : _CountPill(count: credentials.length),
              ),
            ),

            if (credentials.isEmpty)
              Padding(
                padding: Insets.page,
                child: _EmptyCredentials(
                  onAdd: () =>
                      Navigator.of(context).pushNamed(Routes.credentialRequest),
                ),
              )
            else
              // Full-bleed: the deck runs to both edges so the next card peeks
              // in, which is what tells the user it can be swiped.
              _CredentialDeck(credentials: credentials),

            Gap.h32,
            Padding(
              padding: Insets.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(s.quickActions),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.qr_code_scanner_rounded,
                            label: s.actionScan,
                            onTap: () => Navigator.of(context)
                                .pushNamed(Routes.presentScan),
                          ),
                        ),
                        Gap.w12,
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_card_rounded,
                            label: s.actionAdd,
                            onTap: () => Navigator.of(context)
                                .pushNamed(Routes.credentialRequest),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Where the identity has actually been sent. A wallet that
                  // holds a citizen's ID owes them this record, and it is the
                  // one thing on this screen that changes between visits.
                  Gap.h32,
                  SectionLabel(s.recentActivity),
                  if (wallet.activity.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                      child: Text(
                        s.activityEmpty,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                      child: Column(
                        children: [
                          for (final (i, e) in wallet.activity.indexed)
                            _ActivityRow(
                              entry: e,
                              last: i == wallet.activity.length - 1,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo, greeting, holder status, language switch — set on a tinted panel.
///
/// As four bare lines of text this was the plainest thing on the screen while
/// sitting in its most prominent position. Giving it a surface of its own makes
/// it read as the holder's identity header rather than as a caption, and the
/// tint is kept pale on purpose: the saturated brand gradient belongs to the
/// credential cards below, and a second one up here would fight them.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.protected});

  final String name;

  /// Reflects the real holder-key state rather than being decorative.
  final bool protected;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.surface],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The shipped mark rather than a drawn shield: this is the screen
              // the citizen sees every day, and it should carry the real
              // identity of the programme.
              const AppLogo(height: 30, padding: 9),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.homeGreeting, style: text.bodySmall),
                    Gap.h4,
                    Text(
                      name,
                      style: text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Gap.w8,
              const LanguageToggle(compact: true),
            ],
          ),
          // On its own line rather than inside the name column: stacked as a
          // third line it dragged the logo out of alignment with the name it
          // belongs beside.
          if (protected) ...[
            Gap.h12,
            StatusBadge(
              label: s.homeProtected,
              icon: Icons.verified_user_rounded,
              tone: BadgeTone.success,
            ),
          ],
        ],
      ),
    );
  }
}

/// Swipeable deck of credential cards with a page indicator.
class _CredentialDeck extends StatefulWidget {
  const _CredentialDeck({required this.credentials});

  final List<WalletCredential> credentials;

  @override
  State<_CredentialDeck> createState() => _CredentialDeckState();
}

class _CredentialDeckState extends State<_CredentialDeck> {
  /// Less than 1 so the neighbouring card stays partly visible — the whole
  /// reason a deck reads as swipeable.
  static const double _viewport = 0.88;

  late final PageController _controller =
      PageController(viewportFraction: _viewport);

  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final page = _controller.page ?? 0;
      if (page != _page) setState(() => _page = page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final single = widget.credentials.length == 1;

    return Column(
      children: [
        SizedBox(
          // Sized for the Myanmar text, which sets taller than the English at
          // the same point size and wraps the credential name to a second line
          // where English keeps it on one. Fitting the English content exactly
          // overflows the moment the default locale renders.
          height: 258,
          child: PageView.builder(
            controller: _controller,
            padEnds: true,
            physics: single
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: widget.credentials.length,
            itemBuilder: (context, i) {
              // Cards slightly recede as they move off-centre, which gives the
              // swipe depth instead of sliding flat panels past each other.
              final distance = (_page - i).abs().clamp(0.0, 1.0);
              final scale = 1 - distance * 0.06;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Transform.scale(
                  scale: scale,
                  child: CredentialCard(credential: widget.credentials[i]),
                ),
              );
            },
          ),
        ),
        if (!single) ...[
          Gap.h16,
          _PageDots(count: widget.credentials.length, page: _page),
        ],
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.page});

  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = (page.round() == i);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          // The active dot stretches into a bar rather than just changing
          // colour, so position is readable without relying on hue.
          width: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// How many credentials are held, next to the section label.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: Radii.pill,
      ),
      child: Text(
        '$count',
        style: AppTypography.numeric(
          size: 12,
          weight: FontWeight.w600,
          color: AppColors.primaryDark,
          spacing: 0,
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

/// A quick action, filled in the light brand tint.
///
/// Deliberately *not* the saturated gradient: the credential cards directly
/// above own that treatment, and repeating it here made the actions read as a
/// third credential rather than as controls. The pale fill keeps them clearly
/// interactive and clearly a different class of object.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardAll,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: Radii.cardAll,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    // A solid tile on the tinted ground: without it the icon
                    // floats on a wash of its own colour and loses its edge.
                    color: AppColors.surface,
                    borderRadius: Radii.fieldAll,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                Gap.h16,
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primaryDark),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One past presentation: who received it, how much, and when.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.last});

  final ActivityEntry entry;

  /// Suppresses the divider under the final row.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.md),
          child: Row(
            children: [
              VerifierLogo(name: entry.verifierName, size: 40, onDark: false),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.verifierName,
                      style: text.titleSmall
                          ?.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h4,
                    Text(
                      s.activityShared(entry.claimCount),
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Gap.w8,
              Text(
                entry.date,
                style: AppTypography.numeric(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.textTertiary,
                  spacing: 0,
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}
