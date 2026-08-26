// Renders every designed screen to a PNG so the flow can be reviewed without
// a device. Not part of the normal suite — `flutter test` only walks `test/`.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// Output lands in tool/goldens/. These are previews, not golden assertions:
// running without --update-goldens will fail on any platform whose text
// rasterisation differs, which is expected and not a regression.

import 'dart:io';

import 'package:eid_wallet/core/l10n/app_strings.dart';
import 'package:eid_wallet/core/l10n/locale_controller.dart';
import 'package:eid_wallet/core/models/wallet_models.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/core/router/routes.dart';
import 'package:eid_wallet/core/theme/app_theme.dart';
import 'package:eid_wallet/core/theme/text_scale_clamp.dart';
import 'package:eid_wallet/features/auth/auth_screen.dart';
import 'package:eid_wallet/features/credential/credential_issuing_screen.dart';
import 'package:eid_wallet/features/credential/request_credential_screen.dart';
import 'package:eid_wallet/features/home/wallet_home_screen.dart';
import 'package:eid_wallet/features/keys/create_key_pair_screen.dart';
import 'package:eid_wallet/features/keys/key_pair_created_screen.dart';
import 'package:eid_wallet/features/onboarding/welcome_screen.dart';
import 'package:eid_wallet/features/presentation/confirm_share_screen.dart';
import 'package:eid_wallet/features/presentation/qr_scan_screen.dart';
import 'package:eid_wallet/features/presentation/review_request_screen.dart';
import 'package:eid_wallet/features/presentation/select_credential_screen.dart';
import 'package:eid_wallet/features/registration/otp_screen.dart';
import 'package:eid_wallet/features/registration/registration_method_screen.dart';
import 'package:eid_wallet/features/registration/wallet_ready_screen.dart';
import 'package:eid_wallet/features/security/pin_setup_screen.dart';
import 'package:eid_wallet/features/verifier/reading_data_screen.dart';
import 'package:eid_wallet/features/verifier/verification_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _request = PresentationRequest.sampleBankKyc;
const _args = PresentationArgs(
  request: _request,
  credential: WalletCredential.sampleNationalId,
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadBundledFonts();
  });

  /// Each entry is one reviewable frame: the numbered screen from the design,
  /// captured in both languages.
  final screens = <String, Widget Function()>{
    '01-welcome': () => const WelcomeScreen(),
    '01b-auth': () => const AuthScreen(),
    '02-register-method': () => const RegistrationMethodScreen(),
    '03-verify-otp': () => const OtpScreen(),
    '04-create-pin': () => const PinSetupScreen(),
    '05-wallet-ready': () => const WalletReadyScreen(),
    '06-create-key-pair': () => const CreateKeyPairScreen(),
    '07-key-pair-created': () => const KeyPairCreatedScreen(),
    '08-request-credential': () => const RequestCredentialScreen(),
    '08b-issuing': () => const CredentialIssuingScreen(),
    '09-qr-scan': () => const QrScanScreen(),
    '10-review-request': () => const ReviewRequestScreen(request: _request),
    '11-select-credential': () =>
        const SelectCredentialScreen(request: _request),
    '12-confirm-share': () => const ConfirmShareScreen(args: _args),
    '13-reading-data': () => const ReadingDataScreen(args: _args),
    '14-verification-result': () =>
        const VerificationResultScreen(args: _args),
    '15-wallet-home': () => const WalletHomeScreen(),
  };

  for (final locale in const [Locale('my'), Locale('en')]) {
    final tag = locale.languageCode;

    screens.forEach((name, build) {
      testWidgets('$name ($tag)', (tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // The key is assigned directly rather than through createHolderKey():
        // that method awaits a Future.delayed, which never completes under the
        // test binding's fake clock unless the tester pumps time forward.
        final wallet = WalletState()
          ..seedDemoCredentials()
          ..setBiometrics(true)
          ..holderKey = HolderKey.demo(DateTime(2026, 5, 15, 10, 30));

        // A populated draft makes the registration screen show its selected +
        // filled state and gives the OTP screen a real masked address to
        // display, rather than the empty placeholder. Email, because that is
        // the channel the sign-in flow uses for the code.
        wallet.draft
          ..method = RegistrationMethod.email
          ..email = 'aung.ko@example.com'
          ..phone = '9 123 456 789';

        await tester.pumpWidget(_harness(build(), wallet, locale));

        // Let entrance animations run to rest. A single large pump is not
        // enough: it advances the clock once, so any animation still has only
        // one frame of progress and staggered content can be caught part-way
        // through its fade. Several smaller pumps drive them to completion,
        // without waiting on the repeating ones (the scanner sweep and the
        // reader pulse never settle).
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/$tag/$name.png'),
        );

        // Drain the staged Future.delayed chains — the issuing steps, the
        // reader hand-off, and the OTP screen's 45-second resend countdown.
        // A pending timer at teardown fails the test.
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
      });
    });
  }
}

Widget _harness(Widget child, WalletState wallet, Locale locale) {
  final controller = LocaleController(locale);
  return LocaleScope(
    controller: controller,
    child: WalletScope(
      state: wallet,
      child: MaterialApp(
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
        onGenerateRoute: Routes.onGenerateRoute,
        // Mirrors the production builder so previews reflect the shipped tree.
        builder: (context, child) =>
            AppTextScaleClamp(child: child ?? const SizedBox.shrink()),
        home: child,
      ),
    ),
  );
}

/// The test runner does not apply pubspec font declarations, so the real faces
/// are registered by hand — otherwise every glyph renders as a box and the
/// Myanmar frames are worthless for review.
Future<void> _loadBundledFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('NotoSerifMyanmar', [
    'assets/fonts/NotoSerifMyanmar-Regular.ttf',
    'assets/fonts/NotoSerifMyanmar-Medium.ttf',
    'assets/fonts/NotoSerifMyanmar-SemiBold.ttf',
    'assets/fonts/NotoSerifMyanmar-Bold.ttf',
  ]);
  await load('RobotoSlab', ['assets/fonts/RobotoSlab-Variable.ttf']);

  // Material icons are shipped by the framework, not by this package, so they
  // need registering too — without them every icon renders as an empty box and
  // the previews misrepresent the design.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons =
        '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf';
    if (File(icons).existsSync()) {
      await load('MaterialIcons', [icons]);
    }
  }
}
