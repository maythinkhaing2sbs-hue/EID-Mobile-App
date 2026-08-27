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
import '../../widgets/verifier_logo.dart';

/// Screen 12 - choose which credential to present.
///
/// Only credentials that can actually satisfy the request are offered; anything
/// missing a requested claim is shown greyed with the reason, rather than
/// hidden. A user who owns a passport and is told "no credential available"
/// with no explanation assumes the app is broken.
///
/// Each option is a small dossier rather than a list row: the wallet is asking
/// the holder to pick between two government documents, and "National ID Card"
/// on its own is not enough to decide with. Issuer, validity, wire format and
/// whether the document actually covers the request are all on the card.
class SelectCredentialScreen extends StatefulWidget {
  const SelectCredentialScreen({super.key, required this.request});

  final PresentationRequest request;

  @override
  State<SelectCredentialScreen> createState() => _SelectCredentialScreenState();
}

class _SelectCredentialScreenState extends State<SelectCredentialScreen> {
  String? _selectedId;

  bool _satisfies(WalletCredential c) =>
      widget.request.requestedClaims.every(c.claims.containsKey);

  /// First credential able to satisfy the request, or null if none can.
  WalletCredential? _firstUsable(List<WalletCredential> all) {
    for (final c in all) {
      if (_satisfies(c)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    final credentials = wallet.credentials;

    // Default to the first credential that can satisfy the request.
    _selectedId ??= _firstUsable(credentials)?.id;

    return AppScaffold(
      title: s.chooseCredentialTitle,
      bottomBar: PrimaryButton(
        label: s.continueLabel,
        onPressed: _selectedId == null
            ? null
            : () => Navigator.of(context).pushNamed(
                  Routes.presentConfirm,
                  arguments: PresentationArgs(
                    request: widget.request,
                    credential:
                        credentials.firstWhere((c) => c.id == _selectedId),
                  ),
                ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.chooseCredentialTitle,
            subtitle: s.chooseCredentialSubtitle,
          ),
          Gap.h16,

          // Who the choice is being made for. The verifier was named on the
          // previous screen and is named again on the next one; dropping it
          // here would leave the one screen where the holder commits a
          // specific document without saying who receives it.
          _RequesterStrip(request: widget.request),
          Gap.h24,

          if (credentials.isEmpty)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.inbox_outlined,
                      color: AppColors.textTertiary),
                  Gap.w12,
                  Expanded(
                    child: Text(
                      s.noCredentials,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

          for (final c in credentials) ...[
            _CredentialOption(
              credential: c,
              selected: c.id == _selectedId,
              usable: _satisfies(c),
              onTap: () => setState(() => _selectedId = c.id),
            ),
            Gap.h12,
          ],

          if (credentials.isNotEmpty) ...[
            Gap.h4,
            InfoNote(text: s.sentSecurely, icon: Icons.https_outlined),
          ],
        ],
      ),
    );
  }
}

/// Bundles the two objects the confirm screen needs, so the route argument
/// stays a single typed value.
class PresentationArgs {
  const PresentationArgs({required this.request, required this.credential});

  final PresentationRequest request;
  final WalletCredential credential;
}

/// The verifier, reduced to a single quiet line. Deliberately not the brand
/// panel used on the review screen: on this screen the credentials are the
/// thing being chosen, and two saturated surfaces would fight.
class _RequesterStrip extends StatelessWidget {
  const _RequesterStrip({required this.request});

  final PresentationRequest request;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: Radii.fieldAll,
      ),
      child: Row(
        children: [
          VerifierLogo(name: request.verifierName, size: 38, onDark: false),
          Gap.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.requestFrom,
                  style: text.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  request.verifierName,
                  style: text.titleSmall
                      ?.copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (request.trusted)
            const Icon(Icons.verified_rounded,
                size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

/// One credential, as a chooseable dossier.
///
/// Selection is expressed four ways at once - border, tint, the filled icon
/// tile and the check mark - so the choice is legible to a colour-blind user,
/// in sunlight, and to a screen reader.
class _CredentialOption extends StatelessWidget {
  const _CredentialOption({
    required this.credential,
    required this.selected,
    required this.usable,
    required this.onTap,
  });

  final WalletCredential credential;
  final bool selected;

  /// Whether this credential carries every claim the verifier asked for.
  final bool usable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;
    final active = selected && usable;

    return Semantics(
      selected: active,
      button: true,
      enabled: usable,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: Radii.cardAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? const [Color(0xFFF3F8FF), Color(0xFFE6F0FD)]
                : const [AppColors.surface, AppColors.surface],
          ),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.8 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ]
              : AppColors.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: usable ? onTap : null,
            borderRadius: Radii.cardAll,
            child: Opacity(
              opacity: usable ? 1 : 0.62,
              child: Padding(
                padding: const EdgeInsets.all(Gap.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _KindTile(icon: credential.kind.icon, active: active),
                        Gap.w12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(credential.kind.label(s),
                                  style: text.titleMedium),
                              Gap.h4,
                              Text(credential.issuerName(s),
                                  style: text.bodySmall),
                            ],
                          ),
                        ),
                        Gap.w12,
                        _SelectMark(selected: active),
                      ],
                    ),
                    Gap.h12,
                    const Divider(
                        height: 1, thickness: 1, color: AppColors.divider),
                    Gap.h12,
                    Wrap(
                      spacing: Gap.sm,
                      runSpacing: Gap.sm,
                      children: [
                        _MetaChip(
                          icon: Icons.event_available_rounded,
                          label: s.validUntil(credential.validUntil),
                        ),
                        _MetaChip(label: credential.format, mono: true),
                      ],
                    ),
                    Gap.h12,
                    _MatchLine(usable: usable),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The document icon. Filled with the brand gradient once chosen, so the tile
/// itself reports the selection from across the card.
class _KindTile extends StatelessWidget {
  const _KindTile({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              )
            : null,
        color: active ? null : AppColors.secondary,
        borderRadius: Radii.fieldAll,
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 23,
        color: active ? Colors.white : AppColors.primary,
      ),
    );
  }
}

/// Radio in the unselected state, filled check once chosen.
class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderStrong,
          width: 1.8,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

/// A fact about the document: validity, wire format. Sunken pills so they read
/// as metadata and never compete with the credential name above them.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.icon, this.mono = false});

  final String label;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: Radii.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.textSecondary),
            Gap.w4,
          ],
          // Flexible, not fixed: the Myanmar validity line is three times the
          // length of "Valid until 2030-12-31" and has to be allowed to wrap
          // inside the pill rather than run off the card.
          Flexible(
            child: Text(
              label,
              style: mono
                  ? AppTypography.mono(size: 11)
                  : Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether this document actually covers the request - the fact the choice
/// turns on, and the reason an unusable credential is shown at all instead of
/// being filtered out of the list.
class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.usable});

  final bool usable;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final color = usable ? const Color(0xFF2E7D32) : const Color(0xFF8A6100);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          usable ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          size: 16,
          color: usable ? AppColors.success : AppColors.warning,
        ),
        Gap.w8,
        Expanded(
          child: Text(
            usable ? s.credentialMatches : s.credentialMissing,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
