import 'package:flutter/material.dart';

import '../../features/auth/auth_screen.dart';
import '../../features/credential/credential_issued_screen.dart';
import '../../features/credential/credential_issuing_screen.dart';
import '../../features/credential/credential_pending_screen.dart';
import '../../features/credential/request_credential_screen.dart';
import '../../features/home/wallet_home_screen.dart';
import '../../features/keys/create_key_pair_screen.dart';
import '../../features/keys/key_pair_created_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/presentation/confirm_share_screen.dart';
import '../../features/presentation/qr_scan_screen.dart';
import '../../features/presentation/review_request_screen.dart';
import '../../features/presentation/select_credential_screen.dart';
import '../../features/registration/otp_screen.dart';
import '../../features/registration/registration_method_screen.dart';
import '../../features/registration/wallet_ready_screen.dart';
import '../../features/security/pin_setup_screen.dart';
import '../../features/security/unlock_screen.dart';
import '../../features/verifier/reading_data_screen.dart';
import '../../features/verifier/verification_result_screen.dart';
import '../models/wallet_models.dart';

/// Route names, grouped by the flow they belong to.
///
/// Named routes with a typed `onGenerateRoute` rather than a router package:
/// this app's navigation is a set of short linear flows, and a hand-written
/// generator keeps argument types checked without a codegen step.
abstract final class Routes {
  static const welcome = '/';

  /// Sign in / create account. Takes an optional [AuthMode] argument to open
  /// on a specific tab; defaults to sign-in.
  static const auth = '/auth';
  static const unlock = '/unlock';
  static const home = '/home';

  // Registration
  static const registerMethod = '/register/method';
  static const registerOtp = '/register/otp';
  static const securityPin = '/security/pin';
  static const walletReady = '/wallet/ready';

  // Holder key
  static const keyCreate = '/key/create';
  static const keyCreated = '/key/created';

  // Issuance (OpenID4VCI)
  static const credentialRequest = '/credential/request';
  static const credentialIssuing = '/credential/issuing';

  /// The filed request, waiting on the issuer. Takes an optional `bool`
  /// argument — true when it closes the issuance flow, which drops the back
  /// arrow; false or absent when it is opened from Home to check on progress.
  static const credentialPending = '/credential/pending';

  /// The approved credential. Takes an optional [WalletCredential]; without one
  /// it shows whatever National ID the wallet holds.
  static const credentialIssued = '/credential/issued';

  // Presentation (OpenID4VP)
  static const presentScan = '/present/scan';
  static const presentReview = '/present/review';
  static const presentSelect = '/present/select';
  static const presentConfirm = '/present/confirm';

  // Verifier side
  static const verifierReading = '/verifier/reading';
  static const verifierResult = '/verifier/result';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Route<dynamic> page(Widget child) => MaterialPageRoute<dynamic>(
          builder: (_) => child,
          settings: settings,
        );

    switch (settings.name) {
      case welcome:
        return page(const WelcomeScreen());
      case auth:
        return page(AuthScreen(
          initialMode: _arg<AuthMode>(settings) ?? AuthMode.signIn,
        ));
      case unlock:
        return page(const UnlockScreen());
      case home:
        return page(const WalletHomeScreen());

      case registerMethod:
        return page(const RegistrationMethodScreen());
      case registerOtp:
        return page(const OtpScreen());
      case securityPin:
        return page(const PinSetupScreen());
      case walletReady:
        return page(const WalletReadyScreen());

      case keyCreate:
        return page(const CreateKeyPairScreen());
      case keyCreated:
        return page(const KeyPairCreatedScreen());

      case credentialRequest:
        return page(const RequestCredentialScreen());
      case credentialIssuing:
        return page(const CredentialIssuingScreen());

      case credentialPending:
        return page(CredentialPendingScreen(
          justSubmitted: _arg<bool>(settings) ?? false,
        ));

      case credentialIssued:
        return page(CredentialIssuedScreen(
          credential: _arg<WalletCredential>(settings),
        ));

      case presentScan:
        return page(const QrScanScreen());

      case presentReview:
        return page(ReviewRequestScreen(
          request: _arg<PresentationRequest>(settings) ??
              PresentationRequest.sampleBankKyc,
        ));

      case presentSelect:
        return page(SelectCredentialScreen(
          request: _arg<PresentationRequest>(settings) ??
              PresentationRequest.sampleBankKyc,
        ));

      case presentConfirm:
        final args = _arg<PresentationArgs>(settings);
        if (args == null) return page(const WalletHomeScreen());
        return page(ConfirmShareScreen(args: args));

      case verifierReading:
        final args = _arg<PresentationArgs>(settings);
        if (args == null) return page(const WalletHomeScreen());
        return page(ReadingDataScreen(args: args));

      case verifierResult:
        final args = _arg<PresentationArgs>(settings);
        if (args == null) return page(const WalletHomeScreen());
        return page(VerificationResultScreen(args: args));

      default:
        return page(const WelcomeScreen());
    }
  }

  /// Typed argument read. Returns null instead of throwing when a route is
  /// reached without its argument — for instance via a deep link or a restored
  /// navigation stack — so the app falls back rather than crashing.
  static T? _arg<T>(RouteSettings settings) {
    final value = settings.arguments;
    return value is T ? value : null;
  }
}
