import 'package:eid_wallet/core/models/wallet_models.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/features/presentation/confirm_share_screen.dart';
import 'package:eid_wallet/features/presentation/review_request_screen.dart';
import 'package:eid_wallet/features/presentation/select_credential_screen.dart';
import 'package:eid_wallet/features/verifier/verification_result_screen.dart';
import 'package:eid_wallet/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const request = PresentationRequest.sampleBankKyc;

  group('Review request screen', () {
    testWidgets('names the verifier before listing the requested claims',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(
        wrapScreen(const ReviewRequestScreen(request: request)),
      );

      expect(find.text('ABC Bank'), findsOneWidget);
      expect(find.text('abc-bank.com'), findsOneWidget);
      for (final claim in request.requestedClaims) {
        expect(find.text(claim.label(my)), findsOneWidget);
      }
    });

    testWidgets('offers Decline as a real, reachable choice', (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(
        wrapScreen(const ReviewRequestScreen(request: request)),
      );

      expect(find.text(my.decline), findsOneWidget);
      expect(find.text(my.continueLabel), findsOneWidget);
    });
  });

  group('Select credential screen', () {
    testWidgets('preselects a credential that can satisfy the request',
        (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState()..seedDemoCredentials();

      await tester.pumpWidget(wrapScreen(
        const SelectCredentialScreen(request: request),
        wallet: wallet,
      ));

      expect(find.text(my.credNationalId), findsOneWidget);
      expect(find.text(my.credPassport), findsOneWidget);

      final button = find.widgetWithText(FilledButton, my.continueLabel);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull,
          reason: 'a usable credential should be selected by default');
    });

    testWidgets('blocks Continue when the wallet holds no credentials',
        (tester) async {
      await setPhoneSurface(tester);

      await tester.pumpWidget(wrapScreen(
        const SelectCredentialScreen(request: request),
        wallet: WalletState(),
      ));

      expect(find.text(my.noCredentials), findsOneWidget);
      final button = find.widgetWithText(FilledButton, my.continueLabel);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });
  });

  group('Confirm & share screen', () {
    Widget screen() => wrapScreen(
          ConfirmShareScreen(
            args: const PresentationArgs(
              request: request,
              credential: WalletCredential.sampleNationalId,
            ),
          ),
        );

    testWidgets('shows the actual values, not just the claim names',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(screen());

      expect(find.text('Aung Ko Ko'), findsOneWidget);
      expect(find.text('12/ABC(N)123456'), findsOneWidget);
      expect(find.text('1990-05-15'), findsOneWidget);
    });

    testWidgets('Share is gated behind the explicit consent checkbox',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(screen());

      final share = find.widgetWithText(FilledButton, my.share);
      expect(tester.widget<FilledButton>(share).onPressed, isNull,
          reason: 'nothing may leave the device before consent is given');

      // The consent box sits below the claim list; scroll to it as a user would.
      await tester.scrollUntilVisible(find.byType(Checkbox), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(share).onPressed, isNotNull);
    });
  });

  group('Verification result screen', () {
    testWidgets('reports every cryptographic check alongside the identity',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(
        const VerificationResultScreen(
          args: PresentationArgs(
            request: request,
            credential: WalletCredential.sampleNationalId,
          ),
        ),
      ));

      // Identity first, above the fold.
      expect(find.text(my.verifiedTitle), findsOneWidget);
      expect(find.text('Aung Ko Ko'), findsOneWidget);

      // Then the audit block, which the teller scrolls to.
      for (final check in [
        my.checkSignature,
        my.checkIssuerCert,
        my.checkDataIntegrity,
        my.checkDeviceAuth,
        my.checkRevocation,
      ]) {
        await tester.scrollUntilVisible(find.text(check), 200);
        expect(find.text(check), findsOneWidget);
      }
    });
  });

  group('PinController', () {
    test('fills, backspaces and reports completion', () {
      final pin = PinController();
      expect(pin.isComplete, isFalse);

      for (final d in ['1', '2', '3', '4', '5', '6']) {
        pin.push(d);
      }
      expect(pin.value, '123456');
      expect(pin.isComplete, isTrue);

      pin.push('7');
      expect(pin.value, '123456', reason: 'entry stops at the PIN length');

      pin.backspace();
      expect(pin.value, '12345');
      expect(pin.isComplete, isFalse);
    });

    test('a failure clears the entry and advances the shake trigger', () {
      final pin = PinController()..push('1');
      final before = pin.errorTrigger;

      pin.fail();

      expect(pin.value, isEmpty);
      expect(pin.hasError, isTrue);
      expect(pin.errorTrigger, before + 1);

      pin.push('9');
      expect(pin.hasError, isFalse,
          reason: 'typing again should dismiss the error state');
    });
  });

  group('WalletState', () {
    test('issuing a credential is idempotent', () async {
      final wallet = WalletState();
      await wallet.issueCredential();
      await wallet.issueCredential();

      expect(wallet.credentials.length, 1);
    });

    test('creating the holder key records a P-256 key', () async {
      final wallet = WalletState();
      expect(wallet.hasHolderKey, isFalse);

      final key = await wallet.createHolderKey();

      expect(wallet.hasHolderKey, isTrue);
      expect(key.algorithm, contains('P-256'));
      expect(key.publicKeyBase64, isNotEmpty);
    });

    test('the OTP target is masked for display', () {
      final draft = RegistrationDraft(
        phone: '9123456789',
        method: RegistrationMethod.phone,
      );
      expect(draft.otpTarget, isNot(contains('456')));
      expect(draft.otpTarget, endsWith('789'));

      final byEmail = RegistrationDraft(
        email: 'aung.ko@example.com',
        method: RegistrationMethod.email,
      );
      expect(byEmail.otpTarget, 'a******@example.com');
    });
  });
}
