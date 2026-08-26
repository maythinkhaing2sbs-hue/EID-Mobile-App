import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Six-box one-time-code entry.
///
/// Implemented as a single hidden [EditableText] behind six painted boxes
/// rather than six real fields. That is what makes SMS autofill, paste of a
/// whole code, and backspace-across-boxes all behave — six separate
/// controllers get all three of those wrong.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.errorText,
    this.onChanged,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focus = FocusNode();

  String get _value => _controller.text;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged?.call(_value);
    if (_value.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onCompleted(_value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // The real input, kept invisible but focusable and autofill-aware.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableSuggestions: false,
                  maxLength: widget.length,
                  showCursor: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _focus.requestFocus,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (i) {
                  final filled = i < _value.length;
                  final active = i == _value.length && _focus.hasFocus;
                  return _OtpBox(
                    digit: filled ? _value[i] : '',
                    active: active,
                    error: hasError,
                  );
                }),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          Gap.h8,
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.danger),
              Gap.w4,
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Lets the parent clear the field after a failed verification.
  void clear() => _controller.clear();
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.active,
    required this.error,
  });

  final String digit;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final Color border = error
        ? AppColors.danger
        : active
            ? AppColors.primary
            : digit.isEmpty
                ? AppColors.border
                : AppColors.borderStrong;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: 60,
      width: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.fieldAll,
        border: Border.all(color: border, width: active || error ? 1.8 : 1),
        boxShadow: active ? AppColors.cardShadow : null,
      ),
      child: Text(
        digit,
        style: AppTypography.numeric(
          size: 24,
          weight: FontWeight.w600,
          color: error ? AppColors.danger : AppColors.textPrimary,
          spacing: 0,
        ),
      ),
    );
  }
}

/// Counts down to zero, then swaps itself for a "Resend code" action.
class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    required this.seconds,
    required this.onResend,
    required this.waitingLabel,
    required this.resendLabel,
  });

  final int seconds;
  final VoidCallback onResend;

  /// Receives the formatted `mm:ss` string.
  final String Function(String) waitingLabel;
  final String resendLabel;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  late int _remaining = widget.seconds;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _remaining > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _remaining--);
    }
    if (mounted) setState(() => _running = false);
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _restart() {
    widget.onResend();
    setState(() {
      _remaining = widget.seconds;
      _running = true;
    });
    _tick();
  }

  @override
  Widget build(BuildContext context) {
    if (_running) {
      return Text(
        widget.waitingLabel(_formatted),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return TextButton(
      onPressed: _restart,
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Text(widget.resendLabel),
    );
  }
}
