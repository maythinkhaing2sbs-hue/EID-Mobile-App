import 'package:eid_wallet/core/models/wallet_models.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/features/auth/auth_screen.dart';
import 'package:eid_wallet/features/onboarding/welcome_screen.dart';
import 'package:eid_wallet/features/registration/eid_registration_screen.dart';
import 'package:eid_wallet/features/registration/registration_method_screen.dart';
import 'package:eid_wallet/widgets/app_text_field.dart';
import 'package:eid_wallet/widgets/auth_field.dart';
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

    test('English name field rejects non-Latin input', () {
      expect(Validators.isLatinName('Aung Ko Ko'), isTrue);
      expect(Validators.isLatinName('အောင်ကိုကို'), isFalse);
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
        // Submitting pushes the OTP screen, whose resend countdown would still
        // be running at teardown. This test is about the draft, not the route.
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
  });
  group('Registration method screen', () {
    testWidgets('Continue stays disabled until a method is chosen',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const RegistrationMethodScreen()));

      final button = find.widgetWithText(FilledButton, my.continueLabel);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      // The third card sits below the fold on a 390×844 device, so scroll it
      // into view the way a user would before tapping.
      final uidCard = find.text(my.methodUid);
      await tester.ensureVisible(uidCard);
      await tester.pumpAndSettle();
      await tester.tap(uidCard);
      await tester.pump();

      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    testWidgets('records the chosen method on the draft', (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      await tester.pumpWidget(
        wrapScreen(const RegistrationMethodScreen(), wallet: wallet),
      );

      await tester.tap(find.text(my.methodEmail));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, my.continueLabel));
      await tester.pumpAndSettle();

      expect(wallet.draft.method, RegistrationMethod.email);
    });
  });

  group('EID registration form', () {
    testWidgets('surfaces an error for every empty required field',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const EidRegistrationScreen()));

      await tester.tap(find.widgetWithText(FilledButton, my.next));
      await tester.pumpAndSettle();

      // Six required fields; the shared "required" message appears for the
      // ones currently on screen.
      expect(find.text(my.errRequired), findsWidgets);
    });

    testWidgets('rejects a Myanmar-script entry in the English name field',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const EidRegistrationScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, my.fieldNameEn),
        'အောင်ကိုကို',
      );
      await tester.pumpAndSettle();

      expect(find.text(my.errNameEn), findsOneWidget);
    });

    testWidgets('rejects a malformed UID and accepts a valid one',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const EidRegistrationScreen()));

      final uidField = find.widgetWithText(TextFormField, my.fieldUid);

      await tester.enterText(uidField, '12/ABC123');
      await tester.pumpAndSettle();
      expect(find.text(my.errUid), findsOneWidget);

      await tester.enterText(uidField, '12/ABC(N)123456');
      await tester.pumpAndSettle();
      expect(find.text(my.errUid), findsNothing);
    });

    testWidgets('opens the date picker and records the chosen date',
        (tester) async {
      // Regression: an app-wide clamp of minScaleFactor: 1 crashed this dialog.
      // The date picker re-clamps its header to a max of exactly 1.0, which
      // composed to min == max == 1.0 and tripped Flutter's own
      // assert(maxScale > minScale). The clamp is now a ceiling only.
      await setPhoneSurface(tester);
      final wallet = WalletState();
      await tester.pumpWidget(
        wrapScreen(const EidRegistrationScreen(), wallet: wallet),
      );

      final dobField = find.widgetWithText(InputDecorator, my.fieldDob);
      await tester.ensureVisible(dobField);
      await tester.pumpAndSettle();
      await tester.tap(dobField);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget,
          reason: 'tapping the date field must open the picker, not crash');

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      // The picker defaults to 25 years ago; whatever it returned must have
      // been written back to the field in ISO form.
      final expected = DateField.format(DateTime(DateTime.now().year - 25));
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('uppercases UID input as it is typed', (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const EidRegistrationScreen()));

      final uidField = find.widgetWithText(TextFormField, my.fieldUid);
      await tester.enterText(uidField, '12/abc(n)123456');
      await tester.pumpAndSettle();

      // Asserted on the field's own controller: the hint text happens to be a
      // sample UID too, so a plain find.text would match twice.
      final editable = tester.widget<EditableText>(
        find.descendant(of: uidField, matching: find.byType(EditableText)),
      );
      expect(editable.controller.text, '12/ABC(N)123456');
    });
  });
}
