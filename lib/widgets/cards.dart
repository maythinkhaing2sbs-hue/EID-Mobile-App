import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/models/wallet_models.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Base white surface with the house radius, border and soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = Insets.card,
    this.onTap,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardAll,
        child: content,
      ),
    );
  }
}

/// Large tappable option card — registration methods, credential choices.
/// Selection is expressed three ways at once (border, tint, radio) so it reads
/// correctly for colour-blind users and in bright sunlight.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.leading,
    this.selected = false,
    this.showRadio = true,
    this.badge,
    this.trailingChevron = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final bool showRadio;
  final String? badge;
  final bool trailingChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      selected: showRadio ? selected : null,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.surface,
          borderRadius: Radii.cardAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? null : AppColors.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: Radii.cardAll,
            child: Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null)
                    leading!
                  else if (icon != null)
                    _IconBadge(icon: icon!, active: selected),
                  if (leading != null || icon != null) Gap.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(title, style: text.titleMedium),
                            ),
                            if (badge != null) ...[
                              Gap.w8,
                              _Pill(label: badge!),
                            ],
                          ],
                        ),
                        if (subtitle != null) ...[
                          Gap.h4,
                          Text(subtitle!, style: text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (showRadio) ...[
                    Gap.w12,
                    _Radio(selected: selected),
                  ] else if (trailingChevron) ...[
                    Gap.w8,
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textTertiary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.secondary,
        borderRadius: Radii.fieldAll,
      ),
      child: Icon(
        icon,
        size: 22,
        color: active ? AppColors.surface : AppColors.primary,
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderStrong,
          width: 1.8,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: Radii.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: const Color(0xFF8A6100)),
      ),
    );
  }
}

/// Label on the left, value on the right — key details, verification results.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.numericValue = false,
    this.dense = false,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  /// Renders the value in the tabular-figure face — dates, numbers, IDs.
  final bool numericValue;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 5 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: text.bodySmall),
          ),
          Gap.w12,
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle ??
                  (numericValue
                      ? AppTypography.numeric(size: 14, weight: FontWeight.w600)
                      : text.titleSmall
                          ?.copyWith(color: AppColors.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One requested/shared claim with a green check — the pattern used on the
/// verifier request, the consent screen and the issuance summary.
class ClaimRow extends StatelessWidget {
  const ClaimRow({
    super.key,
    required this.label,
    this.value,
    this.checked = true,
  });

  final String label;
  final String? value;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: checked ? AppColors.success : AppColors.borderStrong,
          ),
          Gap.w8,
          Expanded(
            child: Text(
              label,
              style: text.bodyLarge?.copyWith(fontSize: 15),
            ),
          ),
          if (value != null) ...[
            Gap.w8,
            Text(value!, style: AppTypography.numeric(size: 14)),
          ],
        ],
      ),
    );
  }
}

/// Status chip: success / pending / warning.
enum BadgeTone { success, info, warning, danger }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.success,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (tone) {
      BadgeTone.success => (const Color(0xFF2E7D32), AppColors.successSurface),
      BadgeTone.info => (AppColors.primaryDark, AppColors.secondary),
      BadgeTone.warning => (const Color(0xFF8A6100), AppColors.warningSurface),
      BadgeTone.danger => (AppColors.danger, AppColors.dangerSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), Gap.w4],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// The credential itself, drawn as an ID card. This is the object the whole
/// app exists to hold, so it gets the one saturated gradient surface in the
/// product — everything else stays quiet around it.
class CredentialCard extends StatelessWidget {
  const CredentialCard({
    super.key,
    required this.credential,
    this.compact = false,
    this.onTap,
  });

  final WalletCredential credential;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final holder = credential.claims[ClaimId.fullName] ?? '—';
    final number = credential.claims[ClaimId.documentNumber] ?? '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Gap.xl),
        decoration: BoxDecoration(
          borderRadius: Radii.cardAll,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: AppColors.raisedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_rounded,
                    size: 20, color: Colors.white70),
                Gap.w8,
                Expanded(
                  child: Text(
                    credential.issuerName(s),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: Radii.pill,
                  ),
                  child: Text(
                    credential.format,
                    style: AppTypography.mono(size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            Gap.h16,
            Text(
              credential.kind.label(s),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            if (!compact) ...[
              Gap.h24,
              Text(
                holder.toUpperCase(),
                style: AppTypography.numeric(
                  size: 18,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  spacing: 1.2,
                ),
              ),
              Gap.h4,
              Text(
                number,
                style: AppTypography.numeric(
                  size: 13,
                  weight: FontWeight.w400,
                  color: Colors.white70,
                  spacing: 1.4,
                ),
              ),
            ],
            Gap.h16,
            Row(
              children: [
                const Icon(Icons.verified_rounded,
                    size: 15, color: Colors.white70),
                Gap.w4,
                Text(
                  s.validUntil(credential.validUntil),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiet informational block — security notes, "what happens next" copy.
class InfoNote extends StatelessWidget {
  const InfoNote({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline_rounded,
    this.tone = BadgeTone.info,
  });

  final String text;
  final IconData icon;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (tone) {
      BadgeTone.success => (const Color(0xFF2E7D32), AppColors.successSurface),
      BadgeTone.info => (AppColors.primaryDark, AppColors.secondary),
      BadgeTone.warning => (const Color(0xFF8A6100), AppColors.warningSurface),
      BadgeTone.danger => (AppColors.danger, AppColors.dangerSurface),
    };

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.fieldAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          Gap.w8,
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: fg, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
