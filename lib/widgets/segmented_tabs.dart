import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';

/// Two-up segmented control: a sunken track with a raised white thumb that
/// slides to the active segment.
///
/// Used for Sign in / Create account. A segmented control rather than a link
/// pair because both destinations are equally likely on first launch, and the
/// thumb makes the current one unambiguous — which matters when the two forms
/// differ only by one field.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = labels.length;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // The thumb. Aligned rather than positioned so it tracks the real
          // width of the row at any text scale.
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: count == 1
                  ? Alignment.center
                  : Alignment(-1 + 2 * index / (count - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1416202E),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(count, (i) {
              final active = i == index;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: active,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: active ? null : () => onChanged(i),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: (text.labelLarge ?? const TextStyle()).copyWith(
                          color: active
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
