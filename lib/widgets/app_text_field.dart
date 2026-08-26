import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Form field with a floating label.
///
/// Two details matter for this app specifically: [numeric] switches the *input*
/// face to Roboto Slab (so a UID or phone number is read digit-by-digit even in
/// the Myanmar locale), and validation is surfaced inline under the field
/// rather than in a dialog, because a citizen filling six fields needs to see
/// which one is wrong without losing the rest of the form.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.inputFormatters,
    this.numeric = false,
    this.prefix,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool numeric;
  final String? prefix;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      autofillHints: autofillHints,
      maxLength: maxLength,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: numeric
          ? AppTypography.numeric(size: 16, weight: FontWeight.w500, spacing: 0.3)
          : Theme.of(context).textTheme.bodyLarge,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        counterText: '',
        prefixText: prefix,
        prefixStyle:
            AppTypography.numeric(size: 16, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Read-only field that opens a date picker. Values render in the numeric face
/// and in ISO order, which is how dates appear on the physical ID card.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
    this.hint,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? Function(DateTime?)? validator;
  final String? hint;

  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        // Keep the FormField's own value in step with the parent's.
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(value);
          });
        }

        return InkWell(
          borderRadius: Radii.fieldAll,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(now.year - 25),
              firstDate: DateTime(1900),
              lastDate: now,
              initialEntryMode: DatePickerEntryMode.calendar,
            );
            if (picked != null) {
              field.didChange(picked);
              onChanged(picked);
            }
          },
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_today_rounded,
                  size: 18, color: AppColors.textTertiary),
            ),
            child: value == null
                ? null
                : Text(
                    format(value!),
                    style: AppTypography.numeric(
                        size: 16, weight: FontWeight.w500, spacing: 0.3),
                  ),
          ),
        );
      },
    );
  }
}

/// Formatter for the Myanmar NRC/UID shape `12/ABC(N)123456`.
///
/// Only uppercases and trims length; it deliberately does not force the
/// punctuation, because township codes vary and fighting the user mid-typing
/// is worse than validating once on submit.
class UidInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(
      text: upper,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

/// Shared field validators. Keeping them here means the error copy and the rule
/// live together and are reused by every form in the app.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone = RegExp(r'^\+?[\d\s-]{7,15}$');
  static final RegExp _latin = RegExp(r'^[A-Za-z\s.\-]+$');

  /// `12/ABC(N)123456` — township digits, three-letter code, category letter,
  /// six digits. Spaces are tolerated and stripped before matching.
  static final RegExp _uid = RegExp(r'^\d{1,2}/[A-Z]{2,10}\([A-Z]\)\d{6}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());
  static bool isPhone(String v) => _phone.hasMatch(v.trim());
  static bool isLatinName(String v) => _latin.hasMatch(v.trim());
  static bool isUid(String v) => _uid.hasMatch(v.replaceAll(' ', '').trim());
}
