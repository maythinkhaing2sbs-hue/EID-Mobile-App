import 'package:flutter/widgets.dart';

import 'app_strings.dart';

/// Holds the active locale for the whole app.
///
/// The language toggle lives on the Welcome screen but has to work from any
/// screen the user later lands on, so the notifier is hoisted above
/// `MaterialApp` and read through [LocaleScope].
class LocaleController extends ValueNotifier<Locale> {
  LocaleController([super.initial = AppStrings.fallback]);

  bool get isMyanmar => value.languageCode == 'my';

  void setLocale(Locale locale) => value = locale;

  /// Flips between the two supported languages. The whole app re-themes,
  /// because the text theme is rebuilt per locale.
  void toggle() =>
      value = isMyanmar ? const Locale('en') : const Locale('my');
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LocaleScope>()!
          .notifier!;

  /// Non-listening read, for callbacks that only need to *set* the locale.
  static LocaleController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LocaleScope>()!.notifier!;
}
