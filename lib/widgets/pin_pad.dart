import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

import '../core/theme/app_typography.dart';

/// Masked PIN indicator.
///
/// Each dot fills with a short spring as it lands, so the user gets positional
/// feedback without looking away from the keypad — which is where their eyes
/// actually are while typing.
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
    return Semantics(
      label: '$filled of $length digits entered',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (i) {
          final on = i < filled;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: on ? 16 : 12,
            width: on ? 16 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error
                  ? AppColors.danger
                  : on
                      ? AppColors.primary
                      : AppColors.surfaceSunken,
              border: on
                  ? null
                  : Border.all(color: AppColors.borderStrong, width: 1.4),
            ),
          );
        }),
      ),
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
/// key in the bottom-left corner.
///
/// Each digit sits on its own raised tile. Bare numerals floating on the page
/// read as unfinished and give no press target — the tile is what makes this
/// feel like a keypad rather than a list of numbers.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.biometricIcon = Icons.fingerprint_rounded,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final IconData biometricIcon;

  /// Disabled while a PIN is being validated, so a fast typist cannot push
  /// digits into the next stage.
  final bool enabled;

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in row)
                _Key(
                  label: d,
                  onTap: enabled
                      ? () {
                          HapticFeedback.selectionClick();
                          onDigit(d);
                        }
                      : null,
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Key(
              flat: true,
              icon: onBiometric == null ? null : biometricIcon,
              iconColor: AppColors.primary,
              onTap: onBiometric == null || !enabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onBiometric!();
                    },
            ),
            _Key(
              label: '0',
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onDigit('0');
                    }
                  : null,
            ),
            _Key(
              flat: true,
              icon: Icons.backspace_outlined,
              iconColor: AppColors.textSecondary,
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onBackspace();
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    this.label,
    this.icon,
    this.iconColor,
    this.onTap,
    this.flat = false,
  });

  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// Utility keys (biometric, backspace) sit flat on the page so the ten
  /// digits stay the only raised targets.
  final bool flat;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.onTap != null;
    final bool raised = !widget.flat;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: GestureDetector(
        onTapDown: interactive ? (_) => _set(true) : null,
        onTapUp: interactive ? (_) => _set(false) : null,
        onTapCancel: interactive ? () => _set(false) : null,
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 66,
            width: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: raised
                  ? (_down ? AppColors.secondary : AppColors.surface)
                  : (_down ? AppColors.surfaceSunken : Colors.transparent),
              border: raised
                  ? Border.all(
                      color:
                          _down ? AppColors.primary : AppColors.border,
                      width: _down ? 1.6 : 1,
                    )
                  : null,
              boxShadow: raised && !_down ? AppColors.cardShadow : null,
            ),
            child: Center(
              child: widget.label != null
                  ? Text(
                      widget.label!,
                      style: AppTypography.numeric(
                        size: 25,
                        weight: FontWeight.w500,
                        color: _down
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        spacing: 0,
                      ),
                    )
                  : widget.icon == null
                      ? const SizedBox.shrink()
                      : Icon(widget.icon, size: 24, color: widget.iconColor),
            ),
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
  String? _error;
  int errorTrigger = 0;

  String get value => _value;
  int get filled => _value.length;
  bool get isComplete => _value.length == length;
  bool get hasError => _error != null;

  /// Which failure occurred, so the screen can pick the right message.
  PinError? get error => _error == null ? null : PinError.values.byName(_error!);

  void push(String digit) {
    if (_value.length >= length) return;
    if (_error != null) _error = null;
    _value += digit;
    notifyListeners();
  }

  void backspace() {
    if (_value.isEmpty) return;
    _value = _value.substring(0, _value.length - 1);
    _error = null;
    notifyListeners();
  }

  void fail(PinError reason) {
    _error = reason.name;
    errorTrigger++;
    _value = '';
    notifyListeners();
  }

  void clear() {
    _value = '';
    _error = null;
    notifyListeners();
  }

  /// Rejects the PINs that dominate real-world breach data: every digit the
  /// same, and straight runs in either direction. A national ID wallet that
  /// happily accepts `123456` is not protecting anyone.
  static bool isWeak(String pin) {
    if (pin.length < 2) return false;

    final codes = pin.codeUnits;
    var allSame = true;
    var ascending = true;
    var descending = true;

    for (var i = 1; i < codes.length; i++) {
      final delta = codes[i] - codes[i - 1];
      if (delta != 0) allSame = false;
      if (delta != 1) ascending = false;
      if (delta != -1) descending = false;
    }

    return allSame || ascending || descending;
  }
}

enum PinError { mismatch, weak }
