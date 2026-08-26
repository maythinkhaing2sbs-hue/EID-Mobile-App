import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Sign-in / sign-up form field: a soft filled capsule with a leading icon and
/// no border until it takes focus.
///
/// Deliberately not [AppTextField]. That one carries a floating label and an
/// outline, which is right for the long registration form where a filled field
/// must still announce what it holds once scrolled past. The auth screen is
/// four fields on one card, each unmistakable from its icon and placeholder, so
/// it drops the label and gains the calmer surface of the reference design.
///
/// Like [AppTextField], [numeric] switches the *input* face to Roboto Slab so a
/// phone number or UID is read digit-by-digit even in the Myanmar locale.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.icon,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.inputFormatters,
    this.numeric = false,
    this.prefix,
    this.helper,
    this.autofillHints,
    this.maxLength,
  });

  final IconData icon;

  /// Placeholder, and the field's accessible name.
  final String hint;

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool numeric;
  final String? prefix;

  /// Format hint that must stay visible while the field is being filled —
  /// the UID pattern, for instance. Left null on fields whose placeholder
  /// already says everything.
  final String? helper;

  final Iterable<String>? autofillHints;
  final int? maxLength;

  static const Color _fill = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Burmese sets larger than Latin at the same point size — the script needs
    // room above and below the baseline for its marks — so at the Latin body
    // size a row of four fields turns into a wall. Myanmar therefore drops a
    // step and tightens the capsule; English keeps the full size.
    final bool isMyanmar =
        Localizations.localeOf(context).languageCode == 'my';
    final double fontSize = isMyanmar ? 14 : 16;
    final double padY = isMyanmar ? 14 : 18;

    OutlineInputBorder border(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: AppColors.primary,
      style: numeric
          ? AppTypography.numeric(
              size: fontSize, weight: FontWeight.w500, spacing: 0.3)
          : text.bodyLarge?.copyWith(fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hint,
        labelText: null,
        helperText: helper,
        counterText: '',
        prefixText: prefix,
        prefixStyle: AppTypography.numeric(
            size: fontSize, color: AppColors.textSecondary),
        prefixIcon: Icon(icon,
            size: isMyanmar ? 18 : 20, color: AppColors.textTertiary),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 46, minHeight: 46),
        filled: true,
        fillColor: _fill,
        isDense: true,
        contentPadding: EdgeInsets.fromLTRB(4, padY, 16, padY),
        hintStyle: text.bodyLarge
            ?.copyWith(fontSize: fontSize, color: AppColors.textTertiary),
        helperStyle: text.labelSmall,
        errorStyle: text.labelSmall?.copyWith(color: AppColors.danger),
        // Transparent at rest so the capsule reads as one flat surface; the
        // brand outline only appears on focus.
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
      ),
    );
  }
}
