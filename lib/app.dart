import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_strings.dart';
import 'core/l10n/locale_controller.dart';
import 'core/models/wallet_state.dart';
import 'core/router/current_route.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/text_scale_clamp.dart';
import 'widgets/device_frame.dart';

/// Root widget.
///
/// The locale controller and wallet state are hoisted above `MaterialApp` so a
/// language change re-themes and re-translates every route at once — including
/// routes already on the stack — and so wallet state survives navigation.
class EidWalletApp extends StatefulWidget {
  const EidWalletApp({super.key});

  @override
  State<EidWalletApp> createState() => _EidWalletAppState();
}

class _EidWalletAppState extends State<EidWalletApp> {
  final LocaleController _locale = LocaleController();
  final WalletState _wallet = WalletState();
  final CurrentRouteObserver _routeObserver = CurrentRouteObserver();

  /// Screens whose background is dark, so the mockup's simulated status bar
  /// switches to white — the same call a real app makes with
  /// `SystemUiOverlayStyle.light`.
  static const Set<String> _darkScreens = {Routes.presentScan};

  @override
  void dispose() {
    _locale.dispose();
    _wallet.dispose();
    _routeObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _locale,
      child: WalletScope(
        state: _wallet,
        child: ValueListenableBuilder<Locale>(
          valueListenable: _locale,
          builder: (context, locale, _) => MaterialApp(
            title: 'National EID Wallet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(locale),
            locale: locale,
            supportedLocales: AppStrings.supported,
            localizationsDelegates: const [
              AppStringsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: Routes.welcome,
            onGenerateRoute: Routes.onGenerateRoute,
            navigatorObservers: [_routeObserver],
            builder: (context, child) => AppTextScaleClamp(
              // On a desktop-sized viewport the app is presented inside a
              // phone mockup; on a handset this is a pass-through. It wraps
              // the Navigator, so dialogs and sheets stay inside the phone.
              child: ValueListenableBuilder<String?>(
                valueListenable: _routeObserver.current,
                builder: (context, route, _) => DeviceFrame(
                  lightChrome: _darkScreens.contains(route),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
