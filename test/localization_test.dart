import 'package:eid_wallet/core/l10n/app_strings.dart';
import 'package:eid_wallet/features/onboarding/welcome_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('AppStrings', () {
    test('Myanmar is the default locale', () {
      expect(AppStrings.fallback.languageCode, 'my');
      expect(AppStrings.supported.first.languageCode, 'my');
    });

    test('the two locales define exactly the same key set', () {
      // Guards against a half-translated release: a key present in one table
      // and missing from the other silently falls back and ships English copy
      // onto a Myanmar screen.
      final myKeys = AppStrings.myanmarTable.keys.toSet();
      final enKeys = AppStrings.englishTable.keys.toSet();

      expect(myKeys.difference(enKeys), isEmpty,
          reason: 'keys missing from the English table');
      expect(enKeys.difference(myKeys), isEmpty,
          reason: 'keys missing from the Myanmar table');
    });

    test('no getter resolves to a bare key or an empty string', () {
      // `_s` returns the key itself when it is absent from both tables, so a
      // getter naming a key that was never added would render as `otpTitle`
      // on screen. This catches that.
      for (final resolve in _allGetters) {
        for (final table in [my, en]) {
          final value = resolve(table);
          expect(value.trim(), isNotEmpty);
          expect(
            AppStrings.englishTable.containsKey(value),
            isFalse,
            reason: 'getter resolved to a raw key: $value',
          );
        }
      }
    });

    test('no string carries an unsubstituted placeholder', () {
      for (final table in [AppStrings.myanmarTable, AppStrings.englishTable]) {
        for (final entry in table.entries) {
          // Only the four templated keys may contain braces.
          const templated = {
            'stepOf',
            'otpSubtitle',
            'resendIn',
            'validUntil',
            'confirmShareSubtitle',
            'consentText',
          };
          if (templated.contains(entry.key)) continue;
          expect(entry.value.contains('{'), isFalse,
              reason: 'stray placeholder in ${entry.key}');
        }
      }
    });

    test('placeholders are substituted, not left in the output', () {
      expect(my.resendIn('00:45'), contains('00:45'));
      expect(my.resendIn('x'), isNot(contains('{t}')));
      expect(en.consentText('ABC Bank'), contains('ABC Bank'));
      expect(en.consentText('ABC Bank'), isNot(contains('{v}')));
      expect(en.validUntil('2030-12-31'), 'Valid until 2030-12-31');
      expect(en.stepOf(2, 4), 'Step 2 of 4');
    });
  });

  group('Language toggle', () {
    testWidgets('switches the whole screen between Myanmar and English',
        (tester) async {
      await setPhoneSurface(tester);
      await tester.pumpWidget(wrapScreen(const WelcomeScreen()));

      expect(find.text(my.welcomeTitle, findRichText: true), findsOneWidget);
      expect(find.text(en.welcomeTitle, findRichText: true), findsNothing);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text(en.welcomeTitle, findRichText: true), findsOneWidget);
      expect(find.text(en.letsGetStarted), findsOneWidget);
      expect(find.text(my.welcomeTitle, findRichText: true), findsNothing);

      await tester.tap(find.text('မြန်မာ'));
      await tester.pumpAndSettle();

      expect(find.text(my.welcomeTitle, findRichText: true), findsOneWidget);
    });
  });
}

/// Every localised getter, so the parity test covers the whole table.
final List<String Function(AppStrings)> _allGetters = [
  (s) => s.appName,
  (s) => s.appNameShort,
  (s) => s.languageName,
  (s) => s.continueLabel,
  (s) => s.back,
  (s) => s.next,
  (s) => s.cancel,
  (s) => s.done,
  (s) => s.close,
  (s) => s.decline,
  (s) => s.share,
  (s) => s.skip,
  (s) => s.change,
  (s) => s.needHelp,
  (s) => s.security,
  (s) => s.welcomeTitle,
  (s) => s.welcomeTitleAccent,
  (s) => s.letsGetStarted,
  (s) => s.issuedByGovernment,
  (s) => s.authTabSignIn,
  (s) => s.authTabSignUp,
  (s) => s.authSignInHeadline,
  (s) => s.authSignInHeadlineSub,
  (s) => s.authSignUpHeadline,
  (s) => s.authSignUpHeadlineSub,
  (s) => s.authSignUpDoneTitle,
  (s) => s.authSignUpDoneBody,
  (s) => s.fieldFullName,
  (s) => s.fieldUidNumber,
  (s) => s.errUidNumber,
  (s) => s.registerMethodTitle,
  (s) => s.registerMethodSubtitle,
  (s) => s.methodPhone,
  (s) => s.methodPhoneDesc,
  (s) => s.methodEmail,
  (s) => s.methodEmailDesc,
  (s) => s.methodUid,
  (s) => s.methodUidDesc,
  (s) => s.recommended,
  (s) => s.fieldPhone,
  (s) => s.fieldEmail,
  (s) => s.fieldUid,
  (s) => s.hintUid,
  (s) => s.errRequired,
  (s) => s.errPhone,
  (s) => s.errEmail,
  (s) => s.errUid,
  (s) => s.otpTitle,
  (s) => s.otpTitleEmail,
  (s) => s.otpSentTo,
  (s) => s.otpHint,
  (s) => s.resendCode,
  (s) => s.verify,
  (s) => s.errOtp,
  (s) => s.pinTitle,
  (s) => s.pinSubtitle,
  (s) => s.pinConfirmTitle,
  (s) => s.pinConfirmSubtitle,
  (s) => s.errPinMismatch,
  (s) => s.errPinWeak,
  (s) => s.pinNeverShare,
  (s) => s.readyTitle,
  (s) => s.readySubtitle,
  (s) => s.readyStepEmail,
  (s) => s.readyStepPin,
  (s) => s.goToKeyPair,
  (s) => s.goToWalletHome,
  (s) => s.keyIntroTitle,
  (s) => s.keyIntroBody,
  (s) => s.keyPointPrivate,
  (s) => s.keyPointBinding,
  (s) => s.keyPointSign,
  (s) => s.createKeyPair,
  (s) => s.holderKey,
  (s) => s.keyStatusNotCreated,
  (s) => s.keyCreatedTitle,
  (s) => s.keyCreatedSubtitle,
  (s) => s.keyType,
  (s) => s.keyCreated,
  (s) => s.keyStatus,
  (s) => s.keyActive,
  (s) => s.viewPublicKey,
  (s) => s.publicKey,
  (s) => s.copied,
  (s) => s.copy,
  (s) => s.getYourIdTitle,
  (s) => s.getYourIdSubtitle,
  (s) => s.credential,
  (s) => s.issuer,
  (s) => s.whatYouGet,
  (s) => s.whatYouGetHint,
  (s) => s.issuerVerified,
  (s) => s.keyRequiredFirst,
  (s) => s.requestCredential,
  (s) => s.issuingTitle,
  (s) => s.stepAuthorize,
  (s) => s.stepConsent,
  (s) => s.stepBindKey,
  (s) => s.stepSign,
  (s) => s.stepStore,
  (s) => s.credentialIssued,
  (s) => s.scanTitle,
  (s) => s.scanSubtitle,
  (s) => s.havingTrouble,
  (s) => s.cameraPlaceholder,
  (s) => s.simulateScan,
  (s) => s.reviewTitle,
  (s) => s.requestFrom,
  (s) => s.theyRequest,
  (s) => s.viewDetails,
  (s) => s.verifierVerified,
  (s) => s.chooseCredentialTitle,
  (s) => s.chooseCredentialSubtitle,
  (s) => s.issuedBy,
  (s) => s.confirmShareTitle,
  (s) => s.consentRequired,
  (s) => s.sentSecurely,
  (s) => s.readingTitle,
  (s) => s.readingSubtitle,
  (s) => s.pleaseWait,
  (s) => s.verifiedTitle,
  (s) => s.verifiedSubtitle,
  (s) => s.verificationStatus,
  (s) => s.checkSignature,
  (s) => s.checkIssuerCert,
  (s) => s.checkDataIntegrity,
  (s) => s.checkDeviceAuth,
  (s) => s.checkRevocation,
  (s) => s.verifiedAt,
  (s) => s.transactionId,
  (s) => s.attrFullName,
  (s) => s.attrDob,
  (s) => s.attrNationality,
  (s) => s.attrDocNumber,
  (s) => s.attrExpiry,
  (s) => s.attrAddress,
  (s) => s.attrPhoto,
  (s) => s.homeGreeting,
  (s) => s.myCredentials,
  (s) => s.quickActions,
  (s) => s.actionScan,
  (s) => s.actionAdd,
  (s) => s.actionSecurity,
  (s) => s.noCredentials,
  (s) => s.credNationalId,
  (s) => s.credPassport,
  (s) => s.credDriverLicense,
  (s) => s.issuerMoha,
  (s) => s.issuerMofa,
  (s) => s.nationalityMm,
];
