import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Masked PIN indicator. Shakes on a mismatch — the failure has to be felt
/// without reading, because at this point in the flow the user is looking at
/// the keypad, not the dots.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    this.length = 6,
    this.error = false,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final on = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          height: on ? 15 : 13,
          width: on ? 15 : 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: error
                ? AppColors.danger
                : on
                    ? AppColors.primary
                    : Colors.transparent,
            border: on
                ? null
                : Border.all(color: AppColors.borderStrong, width: 1.6),
          ),
        );
      }),
    );
  }
}

/// Wraps a child in a horizontal shake, driven by a change to [trigger].
class ShakeOnError extends StatefulWidget {
  const ShakeOnError({super.key, required this.child, required this.trigger});

  final Widget child;
  final int trigger;

  @override
  State<ShakeOnError> createState() => _ShakeOnErrorState();
}

class _ShakeOnErrorState extends State<ShakeOnError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(ShakeOnError old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      HapticFeedback.heavyImpact();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Decaying sine: three diminishing swings, then rest.
        final t = _c.value;
        final dx = t == 0 ? 0.0 : (1 - t) * 12 * _sin(t * 3 * 2 * 3.14159);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }

  double _sin(double x) {
    // Small local sine so this widget stays import-light.
    const twoPi = 6.283185307179586;
    x = x % twoPi;
    final x2 = x * x;
    return x * (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42)));
  }
}

/// The on-screen numeric keypad.
///
/// Deliberately app-drawn rather than the system keyboard: it keeps the digits
/// large and in a fixed position (muscle memory), stops predictive text and
/// clipboard suggestions from touching a PIN, and leaves room for the biometric
/// key in the bottom-right corner.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.biometricIcon = Icons.fingerprint_rounded,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final IconData biometricIcon;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final d in row)
                _Key(
                  child: Text(d, style: AppTypography.numeric(size: 26)),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onDigit(d);
                  },
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Key(
              onTap: onBiometric == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onBiometric!();
                    },
              child: onBiometric == null
                  ? const SizedBox.shrink()
                  : Icon(biometricIcon, size: 28, color: AppColors.primary),
            ),
            _Key(
              child: Text('0', style: AppTypography.numeric(size: 26)),
              onTap: () {
                HapticFeedback.selectionClick();
                onDigit('0');
              },
            ),
            _Key(
              onTap: () {
                HapticFeedback.selectionClick();
                onBackspace();
              },
              child: const Icon(Icons.backspace_outlined,
                  size: 22, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: SizedBox(
        height: 64,
        width: 88,
        child: Material(
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: Radii.pill),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Drives PIN entry state for both the "set" and "confirm" stages.
class PinController extends ChangeNotifier {
  PinController({this.length = 6});

  final int length;
  String _value = '';
  bool _error = false;
  int errorTrigger = 0;

  String get value => _value;
  int get filled => _value.length;
  bool get isComplete => _value.length == length;
  bool get hasError => _error;

  void push(String digit) {
    if (_value.length >= length) return;
    if (_error) _error = false;
    _value += digit;
    notifyListeners();
  }

  void backspace() {
    if (_value.isEmpty) return;
    _value = _value.substring(0, _value.length - 1);
    _error = false;
    notifyListeners();
  }

  void fail() {
    _error = true;
    errorTrigger++;
    _value = '';
    notifyListeners();
  }

  void clear() {
    _value = '';
    _error = false;
    notifyListeners();
  }
}
