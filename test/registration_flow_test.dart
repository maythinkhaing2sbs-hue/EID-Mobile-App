import 'package:eid_wallet/core/models/wallet_models.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/features/auth/auth_screen.dart';
import 'package:eid_wallet/features/onboarding/welcome_screen.dart';
import 'package:eid_wallet/features/registration/registration_method_screen.dart';
import 'package:eid_wallet/features/registration/wallet_ready_screen.dart';
import 'package:eid_wallet/features/security/pin_setup_screen.dart';
import 'package:eid_wallet/widgets/app_text_field.dart';
import 'package:eid_wallet/widgets/auth_field.dart';
import 'package:eid_wallet/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('Validators', () {
    test('accepts well-formed Myanmar UID numbers', () {
      expect(Validators.isUid('12/ABC(N)123456'), isTrue);
      expect(Validators.isUid('9/MAKANA(N)000001'), isTrue);
      expect(Validators.isUid('12 / ABC(N)123456'), isTrue,
          reason: 'spaces are stripped before matching');
    });

    test('rejects malformed UID numbers', () {
      expect(Validators.isUid(''), isFalse);
      expect(Validators.isUid('12/ABC123456'), isFalse,
          reason: 'missing the category letter in brackets');
      expect(Validators.isUid('12/ABC(N)12345'), isFalse,
          reason: 'only five trailing digits');
      expect(Validators.isUid('ABC(N)123456'), isFalse,
          reason: 'missing the township number');
    });

    test('email and phone', () {
      expect(Validators.isEmail('aung.ko@example.com'), isTrue);
      expect(Validators.isEmail('aung.ko@example'), isFalse);
      expect(Validators.isPhone('9 123 456 789'), isTrue);
      expect(Validators.isPhone('12'), isFalse);
    });
  });

  group('Welcome screen', () {
    testWidgets('offers one way forward and the language toggle',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const WelcomeScreen()));

      // Sign in versus register is asked on the next screen, not this one.
      expect(find.widgetWithText(FilledButton, my.letsGetStarted),
          findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('မြန်မာ'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });
  });


  group('Auth screen', () {
    testWidgets('signing in asks for email, phone and UID — but not a name',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const AuthScreen()));

      expect(find.byType(AuthField), findsNWidgets(3));
      expect(find.text(my.fieldFullName), findsNothing);
      expect(find.text(my.fieldEmail), findsOneWidget);
      expect(find.text(my.fieldPhone), findsOneWidget);
      expect(find.text(my.fieldUidNumber), findsOneWidget);
    });

    testWidgets('the Create account tab adds the name field and keeps typing',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const AuthScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, my.fieldEmail),
        'aung.ko@example.com',
      );
      await tester.tap(find.text(my.authTabSignUp));
      await tester.pumpAndSettle();

      expect(find.byType(AuthField), findsNWidgets(4));
      expect(find.text(my.fieldFullName), findsOneWidget);
      // Switching tabs must not throw away what has already been typed.
      expect(find.text('aung.ko@example.com'), findsOneWidget);
    });

    testWidgets('an empty form is rejected field by field', (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const AuthScreen()));

      await tester.tap(find.widgetWithText(FilledButton, my.authTabSignIn));
      await tester.pumpAndSettle();

      expect(find.text(my.errRequired), findsNWidgets(3));
    });

    testWidgets('a completed sign-up is written to the draft', (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      await tester.pumpWidget(wrapScreen(
        const AuthScreen(initialMode: AuthMode.signUp),
        wallet: wallet,
        // Nothing should be pushed at all — the assertion below depends on
        // that — but a stub keeps a regression here as a failed expectation
        // rather than as a stray timer at teardown.
        onGenerateRoute: (settings) =>
            MaterialPageRoute<dynamic>(builder: (_) => const SizedBox()),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, my.fieldFullName), 'Aung Ko Ko');
      await tester.enterText(find.widgetWithText(TextFormField, my.fieldEmail),
          'aung.ko@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, my.fieldPhone), '9 123 456 789');
      await tester.enterText(
          find.widgetWithText(TextFormField, my.fieldUidNumber), 'UID12345678');
      await tester.pumpAndSettle();

      // Four fields push the action below the fold on a 390×844 handset.
      final submit = find.widgetWithText(FilledButton, my.authTabSignUp);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // A Latin name belongs in the English slot, not the Myanmar one.
      expect(wallet.draft.nameEn, 'Aung Ko Ko');
      expect(wallet.draft.nameMy, isEmpty);
      expect(wallet.draft.email, 'aung.ko@example.com');
      expect(wallet.draft.uid, 'UID12345678');
    });

    testWidgets('sign-up confirms, then hands back to the sign-in form',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(
        const AuthScreen(initialMode: AuthMode.signUp),
        // Creating an account must not walk into verification. If it ever
        // does, this route stub is what the test lands on and the sign-in
        // form below is nowhere to be found.
        onGenerateRoute: (settings) =>
            MaterialPageRoute<dynamic>(builder: (_) => const SizedBox()),
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, my.fieldFullName), 'Aung Ko Ko');
      await tester.enterText(find.widgetWithText(TextFormField, my.fieldEmail),
          'aung.ko@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, my.fieldPhone), '9 123 456 789');
      await tester.enterText(
          find.widgetWithText(TextFormField, my.fieldUidNumber), 'UID12345678');
      await tester.pumpAndSettle();

      final submit = find.widgetWithText(FilledButton, my.authTabSignUp);
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text(my.authSignUpDoneTitle), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, my.authTabSignIn));
      await tester.pumpAndSettle();

      // Back on the sign-in form: three fields, no name, and what was typed
      // is still there so signing in is not a second round of typing.
      expect(find.text(my.authSignUpDoneTitle), findsNothing);
      expect(find.byType(AuthField), findsNWidgets(3));
      expect(find.text('aung.ko@example.com'), findsOneWidget);
    });
  });

  group('Registration screen', () {
    testWidgets('Continue is blocked until a method and identifier are given',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const RegistrationMethodScreen()));

      final button = find.widgetWithText(FilledButton, my.continueLabel);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      // Choosing a method alone is not enough — the field it reveals is empty.
      await tester.tap(find.text(my.methodPhone));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, my.fieldPhone),
        '9 123 456 789',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('reveals the field belonging to the chosen method',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const RegistrationMethodScreen()));

      await tester.tap(find.text(my.methodEmail));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, my.fieldEmail), findsOneWidget);
      expect(find.widgetWithText(TextFormField, my.fieldPhone), findsNothing);

      await tester.tap(find.text(my.methodPhone));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, my.fieldPhone), findsOneWidget);
      expect(find.widgetWithText(TextFormField, my.fieldEmail), findsNothing);
    });

    testWidgets('switching method clears the previous identifier',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const RegistrationMethodScreen()));

      await tester.tap(find.text(my.methodPhone));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, my.fieldPhone),
        '9 123 456 789',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(my.methodEmail));
      await tester.pumpAndSettle();

      // A phone number left sitting in the email field would be submitted as
      // an email address.
      expect(find.text('9 123 456 789'), findsNothing);
      final button = find.widgetWithText(FilledButton, my.continueLabel);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('rejects a malformed identifier inline', (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const RegistrationMethodScreen()));

      final uidCard = find.text(my.methodUid);
      await tester.ensureVisible(uidCard);
      await tester.pumpAndSettle();
      await tester.tap(uidCard);
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextFormField, my.fieldUid);
      await tester.enterText(field, '12/ABC123');
      await tester.pumpAndSettle();
      expect(find.text(my.errUid), findsOneWidget);

      await tester.enterText(field, '12/abc(n)123456');
      await tester.pumpAndSettle();
      expect(find.text(my.errUid), findsNothing);

      // The formatter uppercases as the user types.
      final editable = tester.widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      expect(editable.controller.text, '12/ABC(N)123456');
    });

    testWidgets('records method and identifier on the draft', (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      await tester.pumpWidget(
        wrapScreen(const RegistrationMethodScreen(), wallet: wallet),
      );

      await tester.tap(find.text(my.methodEmail));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, my.fieldEmail),
        'aung.ko@example.com',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, my.continueLabel));
      // Not settled: the OTP screen this lands on keeps its icon animating
      // while the user waits for the code, so there is no rest to wait for.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(wallet.draft.method, RegistrationMethod.email);
      expect(wallet.draft.email, 'aung.ko@example.com');

      // The OTP screen also starts a 45-second resend countdown; drain it so
      // no timer is pending at teardown.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    });
  });

  group('PIN setup', () {
    // Pumped by hand rather than settled: the lock badge on this screen
    // animates for as long as the screen is up, so `pumpAndSettle` would
    // wait for a rest that never comes. Half a second covers the stage
    // hand-off and every transition it triggers.
    Future<void> enter(WidgetTester tester, String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.widgetWithText(GestureDetector, digit).first);
        await tester.pump();
      }
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('refuses an obvious PIN before asking for confirmation',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const PinSetupScreen()));

      await enter(tester, '123456');

      expect(find.text(my.errPinWeak), findsOneWidget);
      expect(find.text(my.pinConfirmTitle), findsNothing,
          reason: 'a weak PIN must not advance to the confirm stage');
    });

    testWidgets('advances to confirm, then reports a mismatch',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const PinSetupScreen()));

      await enter(tester, '481902');
      expect(find.text(my.pinConfirmTitle), findsOneWidget);

      await enter(tester, '481903');
      expect(find.text(my.errPinMismatch), findsOneWidget);
    });

    testWidgets('a matching confirmation stores the PIN', (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      await tester.pumpWidget(
        wrapScreen(const PinSetupScreen(), wallet: wallet),
      );

      await enter(tester, '481902');
      await enter(tester, '481902');

      expect(wallet.isRegistered, isTrue);
      expect(wallet.verifyPin('481902'), isTrue);
    });
  });

  group('PinController.isWeak', () {
    test('flags repeated digits and straight runs', () {
      expect(PinController.isWeak('111111'), isTrue);
      expect(PinController.isWeak('000000'), isTrue);
      expect(PinController.isWeak('123456'), isTrue);
      expect(PinController.isWeak('654321'), isTrue);
    });

    test('accepts anything without an obvious pattern', () {
      expect(PinController.isWeak('481902'), isFalse);
      expect(PinController.isWeak('135790'), isFalse);
      expect(PinController.isWeak('112233'), isFalse);
    });
  });

  group('Wallet ready screen', () {
    testWidgets('states what is done and what remains', (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const WalletReadyScreen()));

      expect(find.text(my.readyTitle), findsOneWidget);
      expect(find.text(my.readyStepEmail), findsOneWidget);
      expect(find.text(my.readyStepPin), findsOneWidget);
      // The action leads into key creation, not into the wallet: the wallet
      // is not usable until the holder key exists.
      expect(find.text(my.goToKeyPair), findsOneWidget);
    });
  });
}
