import 'package:eid_wallet/core/models/wallet_models.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/features/onboarding/welcome_screen.dart';
import 'package:eid_wallet/features/registration/eid_registration_screen.dart';
import 'package:eid_wallet/features/registration/registration_method_screen.dart';
import 'package:eid_wallet/widgets/app_text_field.dart';
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
    testWidgets('offers both entry points and the language toggle',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const WelcomeScreen()));

      expect(find.text(my.createWallet), findsOneWidget);
      expect(find.text(my.signInExisting), findsOneWidget);
      expect(find.text('မြန်မာ'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
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
