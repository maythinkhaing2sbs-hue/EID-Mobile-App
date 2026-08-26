import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import 'language_toggle.dart';

/// The chrome every flow screen shares: back affordance, optional step
/// indicator, scrolling body with a consistent gutter, and a bottom action
/// area that stays above the keyboard and the home indicator.
///
/// Centralising this is what keeps the 15 screens feeling like one product —
/// the title sits at the same y on each, and the primary action is always in
/// the same place under the thumb.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.step,
    this.totalSteps,
    this.showBack = true,
    this.showLanguageToggle = true,
    this.bottomBar,
    this.background,
    this.padBody = true,
    this.onBack,
  });

  final Widget child;
  final String? title;
  final int? step;
  final int? totalSteps;
  final bool showBack;
  final bool showLanguageToggle;

  /// Pinned action area. Given a white surface and a hairline top border so it
  /// reads as a separate layer once the body scrolls under it.
  final Widget? bottomBar;
  final Color? background;

  /// Set false when the screen paints its own full-bleed content (the QR
  /// scanner, for instance).
  final bool padBody;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final showProgress = step != null && totalSteps != null;

    return Scaffold(
      backgroundColor: background ?? AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: background ?? AppColors.surfaceMuted,
        automaticallyImplyLeading: false,
        titleSpacing: showBack ? 0 : 20,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null,
        title: title == null
            ? null
            : Text(title!, style: Theme.of(context).textTheme.titleMedium),
        actions: [
          if (showLanguageToggle) const LanguageToggle(compact: true),
          Gap.w4,
        ],
        bottom: showProgress
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: StepProgress(step: step!, total: totalSteps!),
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: padBody ? Insets.page : EdgeInsets.zero,
          child: child,
        ),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : BottomActionBar(child: bottomBar!),
    );
  }
}

/// Pinned bottom action container.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, Gap.md, 20, Gap.md),
          child: child,
        ),
      ),
    );
  }
}

/// Segmented progress bar. Segments rather than a continuous track because a
/// citizen filling in a government form wants to know *how many steps are
/// left*, not an abstract percentage.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $total',
      child: Row(
        children: List.generate(total, (i) {
          final done = i < step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: done ? AppColors.primary : AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Screen headline + supporting line. Used at the top of nearly every screen so
/// the type hierarchy never has to be re-decided per screen.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.align = CrossAxisAlignment.start,
  });

  final String title;
  final String? subtitle;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final centred = align == CrossAxisAlignment.center;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          title,
          style: text.headlineMedium,
          textAlign: centred ? TextAlign.center : TextAlign.start,
        ),
        if (subtitle != null) ...[
          Gap.h8,
          Text(
            subtitle!,
            style: text.bodyMedium,
            textAlign: centred ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );
  }
}

/// Small uppercase-ish label above a group of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppTypography.forLocale(Localizations.localeOf(context))
                  .labelMedium
                  ?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
