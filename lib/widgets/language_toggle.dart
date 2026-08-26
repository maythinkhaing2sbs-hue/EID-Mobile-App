import 'package:flutter/material.dart';

import '../core/l10n/locale_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Global language switch: မြန်မာ / English.
///
/// Rendered as a two-up segmented pill rather than a dropdown, because with
/// exactly two languages a segmented control shows the alternative without a
/// tap — important on the Welcome screen, where a user who cannot read the
/// default language has to be able to find the escape hatch immediately.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, this.compact = false});

  /// Compact drops the pill chrome to a single tappable label — used in app
  /// bars, where the toggle is secondary to the screen's own title.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    final isMyanmar = controller.isMyanmar;

    if (compact) {
      return TextButton(
        onPressed: controller.toggle,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 18),
            Gap.w4,
            Text(
              isMyanmar ? 'EN' : 'မြန်မာ',
              style: AppTypography.numeric(
                size: 13,
                weight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'Language / ဘာသာစကား',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: Radii.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: 'မြန်မာ',
              selected: isMyanmar,
              onTap: () => controller.setLocale(const Locale('my')),
            ),
            _Segment(
              label: 'English',
              selected: !isMyanmar,
              onTap: () => controller.setLocale(const Locale('en')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: Radii.pill,
            boxShadow: selected ? AppColors.cardShadow : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: label == 'မြန်မာ' ? AppFonts.myanmar : AppFonts.latin,
              fontSize: 13,
              height: 1.4,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color:
                  selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
