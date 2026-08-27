import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/icon_motion.dart';

import '../../widgets/pin_pad.dart';
import '../../widgets/pulse_icon.dart';

/// Step 3 — set and confirm the wallet PIN.
///
/// Both stages live in one screen and cross-fade in place. Pushing a second
/// route for the confirmation would let Back strand the user in a half-set PIN;
/// here, Back from the confirm stage returns to entry with the first PIN
/// discarded, which is the only sane recovery.
///
/// Obvious PINs are refused outright — see [PinController.isWeak]. A national
/// ID wallet that accepts `123456` is not protecting anyone.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pin = PinController();
  String? _first;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _pin.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _pin.removeListener(_onPinChanged);
    _pin.dispose();
    super.dispose();
  }

  bool get _confirming => _first != null;

  void _onPinChanged() {
    setState(() {});
    if (!_pin.isComplete || _checking) return;

    final entered = _pin.value;
    setState(() => _checking = true);

    // Give the last dot a beat to land before the stage changes.
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _checking = false);

      if (!_confirming) {
        if (PinController.isWeak(entered)) {
          _pin.fail(PinError.weak);
          return;
        }
        setState(() => _first = entered);
        _pin.clear();
        return;
      }

      if (entered == _first) {
        WalletScope.read(context).setPin(entered);
        Navigator.of(context).pushReplacementNamed(Routes.walletReady);
      } else {
        _pin.fail(PinError.mismatch);
      }
    });
  }

  void _back() {
    if (_confirming) {
      setState(() => _first = null);
      _pin.clear();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    final String? errorText = switch (_pin.error) {
      PinError.mismatch => s.errPinMismatch,
      PinError.weak => s.errPinWeak,
      null => null,
    };

    return AppScaffold(
      // Entering a PIN and confirming it are two steps, not one: they are two
      // pieces of work for the user, and sharing a segment left the bar
      // frozen through the longest stretch of the flow.
      step: _confirming ? 4 : 3,
      totalSteps: 4,
      onBack: _back,
      child: Column(
        children: [
          // The keypad is fixed and the copy above it flexes. On a short
          // handset the heading area compresses and scrolls rather than
          // pushing the keys off the bottom of the screen.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  // Centres the heading block in whatever room is left over,
                  // and scrolls instead of overflowing when there is none.
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Gap.h16,

                      // Stage badge. The lock closes as the user advances,
                      // signalling progress without another line of text.
                      _StageBadge(confirming: _confirming),
                      Gap.h24,

                      // Cross-fade rather than a hard swap: the two stages
                      // differ only in wording, and a jump-cut reads as a
                      // glitch.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: ScreenHeader(
                          key: ValueKey(_confirming),
                          title: _confirming ? s.pinConfirmTitle : s.pinTitle,
                          subtitle: _confirming
                              ? s.pinConfirmSubtitle
                              : s.pinSubtitle,
                          align: CrossAxisAlignment.center,
                        ),
                      ),

                      Gap.h32,
                      ShakeOnError(
                        trigger: _pin.errorTrigger,
                        child: PinDots(
                          filled: _pin.filled,
                          error: _pin.hasError,
                        ),
                      ),

                      // Fixed-height slot so the keypad never shifts when an
                      // error appears.
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: errorText == null ? 0 : 1,
                            duration: const Duration(milliseconds: 160),
                            child: Text(
                              errorText ?? '',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.danger),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          NumericKeypad(
            onDigit: _pin.push,
            onBackspace: _pin.backspace,
            enabled: !_checking,
          ),
          Gap.h8,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.visibility_off_outlined,
                size: 15,
                color: AppColors.textTertiary,
              ),
              Gap.w8,
              Flexible(
                child: Text(
                  s.pinNeverShare,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          Gap.h12,
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.confirming});

  final bool confirming;

  @override
  Widget build(BuildContext context) {
    // Two separate motions: a one-shot pop when the screen arrives, and the
    // colour-and-glyph cross-fade each time the stage advances. Folding them
    // into one controller would re-pop the badge on every stage change.
    return ScaleIn(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: confirming ? AppColors.primary : AppColors.secondary,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          // The glyph keeps turning like a key in a cylinder — the action the
          // keypad below is standing in for.
          child: MotionGlyph(
            key: ValueKey(confirming),
            icon: confirming ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 30,
            color: confirming ? AppColors.surface : AppColors.primary,
            motion: IconMotion.turn,
          ),
        ),
      ),
    );
  }
}
