import 'package:eid_wallet/core/l10n/app_strings.dart';
import 'package:eid_wallet/core/l10n/locale_controller.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/core/router/routes.dart';
import 'package:eid_wallet/core/theme/app_theme.dart';
import 'package:eid_wallet/core/theme/text_scale_clamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a single screen in the same scopes, theme and localisation delegates
/// the real app provides, so widget tests exercise the production widget tree
/// rather than a stripped-down one.
///
/// Pass [onGenerateRoute] to stub navigation. Worth doing when the screen
/// under test pushes one that runs a timer — landing on it would leave the
/// timer pending and fail the test on something it is not about.
Widget wrapScreen(
  Widget child, {
  WalletState? wallet,
  Locale locale = const Locale('my'),
  LocaleController? localeController,
  RouteFactory? onGenerateRoute,
}) {
  final controller = localeController ?? LocaleController(locale);

  return LocaleScope(
    controller: controller,
    child: WalletScope(
      state: wallet ?? WalletState(),
      child: ValueListenableBuilder<Locale>(
        valueListenable: controller,
        builder: (context, active, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(active),
          locale: active,
          supportedLocales: AppStrings.supported,
          localizationsDelegates: const [
            AppStringsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateRoute: onGenerateRoute ?? Routes.onGenerateRoute,
          // Mirrors the production builder. Without it, tests would run under
          // an unclamped MediaQuery and would not catch text-scaler bugs that
          // only appear once the app-wide clamp is in place.
          builder: (context, child) =>
              AppTextScaleClamp(child: child ?? const SizedBox.shrink()),
          home: child,
        ),
      ),
    ),
  );
}

/// Phone-sized surface. Several screens are deliberately dense, and the default
/// 800×600 test window makes them overflow in ways a real device never would.
Future<void> setPhoneSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Convenience accessors for the two string tables.
final AppStrings my = AppStrings.forLocale(const Locale('my'));
final AppStrings en = AppStrings.forLocale(const Locale('en'));
