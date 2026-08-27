import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Hand-rolled localisation table.
///
/// Two supported locales: Myanmar (`my`, the default) and English (`en`).
/// Copy lives in [_my] / [_en] and is reached through the typed getters below,
/// so a mistyped key is a compile error at the call site rather than a stray
/// identifier rendered on a government screen.
class AppStrings {
  const AppStrings._(this.locale, this._t);

  final Locale locale;
  final Map<String, String> _t;

  bool get isMyanmar => locale.languageCode == 'my';

  static const List<Locale> supported = [Locale('my'), Locale('en')];
  static const Locale fallback = Locale('my');

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;

  static AppStrings forLocale(Locale locale) =>
      AppStrings._(locale, locale.languageCode == 'en' ? _en : _my);

  String _s(String key) => _t[key] ?? _en[key] ?? key;

  /// Raw tables, exposed so a test can assert the two locales define exactly
  /// the same key set. A key present in only one table would otherwise fall
  /// through to English and ship untranslated copy onto a Myanmar screen.
  @visibleForTesting
  static Map<String, String> get myanmarTable => _my;

  @visibleForTesting
  static Map<String, String> get englishTable => _en;

  // ── Global ──────────────────────────────────────────────────────────────
  String get appName => _s('appName');
  String get appNameShort => _s('appNameShort');
  String get languageName => _s('languageName');
  String get continueLabel => _s('continue');
  String get back => _s('back');
  String get next => _s('next');
  String get cancel => _s('cancel');
  String get done => _s('done');
  String get close => _s('close');
  String get decline => _s('decline');
  String get share => _s('share');
  String get skip => _s('skip');
  String get change => _s('change');
  String get needHelp => _s('needHelp');
  String get security => _s('security');
  String stepOf(int step, int total) =>
      _s('stepOf').replaceFirst('{a}', '$step').replaceFirst('{b}', '$total');

  // ── 1. Welcome ──────────────────────────────────────────────────────────
  String get welcomeTitle => _s('welcomeTitle');

  /// The run inside [welcomeTitle] that carries the product's name, tinted
  /// brand blue on the screen. Localised because the two scripts name the
  /// wallet differently and place it at opposite ends of the sentence.
  String get welcomeTitleAccent => _s('welcomeTitleAccent');
  String get letsGetStarted => _s('letsGetStarted');
  String get issuedByGovernment => _s('issuedByGovernment');

  // ── 1b. Sign in / Create account ────────────────────────────────────────
  String get authTabSignIn => _s('authTabSignIn');
  String get authTabSignUp => _s('authTabSignUp');
  String get authSignInHeadline => _s('authSignInHeadline');
  String get authSignInHeadlineSub => _s('authSignInHeadlineSub');
  String get authSignUpHeadline => _s('authSignUpHeadline');
  String get authSignUpHeadlineSub => _s('authSignUpHeadlineSub');
  String get authSignUpDoneTitle => _s('authSignUpDoneTitle');
  String get authSignUpDoneBody => _s('authSignUpDoneBody');
  String get fieldFullName => _s('fieldFullName');
  String get fieldUidNumber => _s('fieldUidNumber');
  String get errUidNumber => _s('errUidNumber');

  // ── 2. Registration method + identifier ─────────────────────────────────
  String get registerMethodTitle => _s('registerMethodTitle');
  String get registerMethodSubtitle => _s('registerMethodSubtitle');
  String get methodPhone => _s('methodPhone');
  String get methodPhoneDesc => _s('methodPhoneDesc');
  String get methodEmail => _s('methodEmail');
  String get methodEmailDesc => _s('methodEmailDesc');
  String get methodUid => _s('methodUid');
  String get methodUidDesc => _s('methodUidDesc');
  String get recommended => _s('recommended');
  String get fieldPhone => _s('fieldPhone');
  String get fieldEmail => _s('fieldEmail');
  String get fieldUid => _s('fieldUid');
  String get hintUid => _s('hintUid');
  String get errRequired => _s('errRequired');
  String get errPhone => _s('errPhone');
  String get errEmail => _s('errEmail');
  String get errUid => _s('errUid');

  // ── 3. OTP ──────────────────────────────────────────────────────────────
  String get otpTitle => _s('otpTitle');
  String get otpTitleEmail => _s('otpTitleEmail');
  String get otpSentTo => _s('otpSentTo');
  String get otpHint => _s('otpHint');
  String get resendCode => _s('resendCode');
  String resendIn(String time) => _s('resendIn').replaceFirst('{t}', time);
  String get verify => _s('verify');
  String get errOtp => _s('errOtp');

  // ── 4. PIN ──────────────────────────────────────────────────────────────
  String get pinTitle => _s('pinTitle');
  String get pinSubtitle => _s('pinSubtitle');
  String get pinConfirmTitle => _s('pinConfirmTitle');
  String get pinConfirmSubtitle => _s('pinConfirmSubtitle');
  String get errPinMismatch => _s('errPinMismatch');
  String get errPinWeak => _s('errPinWeak');
  String get pinNeverShare => _s('pinNeverShare');

  // ── 5. Wallet ready ─────────────────────────────────────────────────────
  String get readyTitle => _s('readyTitle');
  String get readySubtitle => _s('readySubtitle');
  String get readyStepEmail => _s('readyStepEmail');
  String get readyStepPin => _s('readyStepPin');
  String get goToKeyPair => _s('goToKeyPair');
  String get goToWalletHome => _s('goToWalletHome');

  // ── 6–7. Holder key pair ────────────────────────────────────────────────
  String get keyIntroTitle => _s('keyIntroTitle');
  String get keyIntroBody => _s('keyIntroBody');
  String get keyPointPrivate => _s('keyPointPrivate');
  String get keyPointBinding => _s('keyPointBinding');
  String get keyPointSign => _s('keyPointSign');
  String get createKeyPair => _s('createKeyPair');
  String get holderKey => _s('holderKey');
  String get keyStatusNotCreated => _s('keyStatusNotCreated');
  String get keyCreatedTitle => _s('keyCreatedTitle');
  String get keyCreatedSubtitle => _s('keyCreatedSubtitle');
  String get keyType => _s('keyType');
  String get keyCreated => _s('keyCreated');
  String get keyStatus => _s('keyStatus');
  String get keyActive => _s('keyActive');
  String get viewPublicKey => _s('viewPublicKey');
  String get publicKey => _s('publicKey');
  String get copied => _s('copied');
  String get copy => _s('copy');

  // ── 8. Request credential ───────────────────────────────────────────────
  String get getYourIdTitle => _s('getYourIdTitle');
  String get getYourIdSubtitle => _s('getYourIdSubtitle');
  String get credential => _s('credential');
  String get issuer => _s('issuer');
  String get whatYouGet => _s('whatYouGet');
  String get whatYouGetHint => _s('whatYouGetHint');
  String get issuerVerified => _s('issuerVerified');
  String get requestCredential => _s('requestCredential');
  String get issuingTitle => _s('issuingTitle');
  String get stepAuthorize => _s('stepAuthorize');
  String get stepConsent => _s('stepConsent');
  String get stepBindKey => _s('stepBindKey');
  String get stepSign => _s('stepSign');
  String get stepStore => _s('stepStore');
  String get credentialIssued => _s('credentialIssued');

  // ── 9. QR scan ──────────────────────────────────────────────────────────
  String get scanTitle => _s('scanTitle');
  String get scanSubtitle => _s('scanSubtitle');
  String get havingTrouble => _s('havingTrouble');
  String get cameraPlaceholder => _s('cameraPlaceholder');
  String get simulateScan => _s('simulateScan');

  // ── 10. Review request ──────────────────────────────────────────────────
  String get reviewTitle => _s('reviewTitle');
  String get requestFrom => _s('requestFrom');
  String get theyRequest => _s('theyRequest');
  String get viewDetails => _s('viewDetails');
  String get verifierVerified => _s('verifierVerified');

  // ── 11. Select credential ───────────────────────────────────────────────
  String get chooseCredentialTitle => _s('chooseCredentialTitle');
  String get chooseCredentialSubtitle => _s('chooseCredentialSubtitle');
  String get issuedBy => _s('issuedBy');
  String get credentialMatches => _s('credentialMatches');
  String get credentialMissing => _s('credentialMissing');
  String validUntil(String date) => _s('validUntil').replaceFirst('{d}', date);

  // ── 12. Confirm & share ─────────────────────────────────────────────────
  String get confirmShareTitle => _s('confirmShareTitle');
  String confirmShareSubtitle(String verifier) =>
      _s('confirmShareSubtitle').replaceFirst('{v}', verifier);
  String consentText(String verifier) =>
      _s('consentText').replaceFirst('{v}', verifier);
  String get consentRequired => _s('consentRequired');
  String get whatYouShare => _s('whatYouShare');
  String get sentSecurely => _s('sentSecurely');

  // ── 13. Reading data ────────────────────────────────────────────────────
  String get readingTitle => _s('readingTitle');
  String get readingSubtitle => _s('readingSubtitle');
  String get pleaseWait => _s('pleaseWait');

  // ── 14. Verification result ─────────────────────────────────────────────
  String get verifiedTitle => _s('verifiedTitle');
  String get verifiedSubtitle => _s('verifiedSubtitle');
  String get verificationStatus => _s('verificationStatus');
  String get checkSignature => _s('checkSignature');
  String get checkIssuerCert => _s('checkIssuerCert');
  String get checkDataIntegrity => _s('checkDataIntegrity');
  String get checkDeviceAuth => _s('checkDeviceAuth');
  String get checkRevocation => _s('checkRevocation');
  String get verifiedAt => _s('verifiedAt');
  String get transactionId => _s('transactionId');

  // ── Credential attributes ───────────────────────────────────────────────
  String get attrFullName => _s('attrFullName');
  String get attrDob => _s('attrDob');
  String get attrNationality => _s('attrNationality');
  String get attrDocNumber => _s('attrDocNumber');
  String get attrExpiry => _s('attrExpiry');
  String get attrAddress => _s('attrAddress');
  String get attrPhoto => _s('attrPhoto');

  // ── Home ────────────────────────────────────────────────────────────────
  String get homeGreeting => _s('homeGreeting');
  String get homeProtected => _s('homeProtected');
  String get recentActivity => _s('recentActivity');
  String get activityEmpty => _s('activityEmpty');
  String activityShared(int n) =>
      _s('activityShared').replaceFirst('{n}', '$n');
  String get myCredentials => _s('myCredentials');
  String get quickActions => _s('quickActions');
  String get actionScan => _s('actionScan');
  String get actionAdd => _s('actionAdd');
  String get actionSecurity => _s('actionSecurity');
  String get noCredentials => _s('noCredentials');

  // ── Credential / issuer names ───────────────────────────────────────────
  String get credNationalId => _s('credNationalId');
  String get credPassport => _s('credPassport');
  String get credDriverLicense => _s('credDriverLicense');
  String get issuerMoha => _s('issuerMoha');
  String get issuerMofa => _s('issuerMofa');
  String get nationalityMm => _s('nationalityMm');

  // ═══════════════════════════════════════════════════════════════════════
  // Myanmar — the default language of the app.
  // ═══════════════════════════════════════════════════════════════════════
  static const Map<String, String> _my = {
    'appName': 'အမျိုးသား EID Wallet',
    'appNameShort': 'EID Wallet',
    'languageName': 'မြန်မာ',
    'continue': 'ဆက်လုပ်ရန်',
    'back': 'နောက်သို့',
    'next': 'ရှေ့သို့',
    'cancel': 'ပယ်ဖျက်ရန်',
    'done': 'ပြီးပါပြီ',
    'close': 'ပိတ်ရန်',
    'decline': 'ငြင်းပယ်ရန်',
    'share': 'မျှဝေရန်',
    'skip': 'ကျော်သွားရန်',
    'change': 'ပြောင်းရန်',
    'needHelp': 'အကူအညီ လိုအပ်ပါသလား?',
    'security': 'လုံခြုံရေး',
    'stepOf': 'အဆင့် {a} / {b}',

    'welcomeTitle': 'National EID Wallet\nမှ ကြိုဆိုပါသည်',
    'welcomeTitleAccent': 'National EID Wallet',
    'letsGetStarted': 'စတင်လိုက်ရအောင်!',
    'issuedByGovernment': 'ပြည်ထောင်စုသမ္မတမြန်မာနိုင်ငံတော်အစိုးရ မှ ထုတ်ပေးသည်',

    'authTabSignIn': 'ဝင်ရောက်ရန်',
    'authTabSignUp': 'အကောင့်ဖွင့်ရန်',
    'authSignInHeadline': 'ပြန်လည် ကြိုဆိုပါသည်',
    'authSignInHeadlineSub': 'သင့် EID Wallet သို့ ဝင်ရောက်ပါ။',
    'authSignUpHeadline': 'အကောင့်အသစ် ဖန်တီးပါ',
    'authSignUpHeadlineSub': 'အချက်အလက် ဖြည့်၍ စတင်လိုက်ပါ။',
    'authSignUpDoneTitle': 'အကောင့် ဖွင့်ပြီးပါပြီ!',
    'authSignUpDoneBody':
        'သင့်အကောင့်ကို ဖန်တီးပြီးပါပြီ။ ဆက်လက်အသုံးပြုရန် ဝင်ရောက်ပါ။',
    'fieldFullName': 'အမည် အပြည့်အစုံ',
    'fieldUidNumber': 'UID နံပါတ်',
    'errUidNumber': 'UID နံပါတ်ကို မှန်ကန်စွာ ထည့်သွင်းပါ။',

    'registerMethodTitle': 'မည်သည့်နည်းဖြင့် စာရင်းသွင်းလိုပါသလဲ?',
    'registerMethodSubtitle':
        'သင့်အတွက် အဆင်ပြေဆုံး နည်းလမ်းတစ်ခုကို ရွေးချယ်ပြီး အချက်အလက် ဖြည့်သွင်းပါ။',
    'methodPhone': 'ဖုန်းနံပါတ်ဖြင့်',
    'methodPhoneDesc': 'အတည်ပြုကုဒ်ကို SMS ဖြင့် ပေးပို့ပါမည်။',
    'methodEmail': 'အီးမေးလ်ဖြင့်',
    'methodEmailDesc': 'အတည်ပြုကုဒ်ကို အီးမေးလ်ဖြင့် ပေးပို့ပါမည်။',
    'methodUid': 'အမျိုးသားမှတ်ပုံတင်နံပါတ်ဖြင့်',
    'methodUidDesc':
        'မှတ်ပုံတင်နံပါတ်ဖြင့် စာရင်းသွင်းပါ။ အစိုးရ မှတ်တမ်းနှင့် တိုက်ဆိုင် စစ်ဆေးပါမည်။',
    'recommended': 'အကြံပြုထားသည်',
    'fieldPhone': 'ဖုန်းနံပါတ်',
    'fieldEmail': 'အီးမေးလ်လိပ်စာ',
    'fieldUid': 'မှတ်ပုံတင်အမှတ် (UID)',
    'hintUid': '12/ABC(N)123456',
    'errRequired': 'ဤအချက်အလက်ကို ဖြည့်သွင်းရန် လိုအပ်ပါသည်။',
    'errPhone': 'ဖုန်းနံပါတ်ကို မှန်ကန်စွာ ထည့်သွင်းပါ။',
    'errEmail': 'အီးမေးလ်လိပ်စာကို မှန်ကန်စွာ ထည့်သွင်းပါ။',
    'errUid': 'မှတ်ပုံတင်အမှတ် ပုံစံ မမှန်ပါ။ ဥပမာ — 12/ABC(N)123456',

    'otpTitle': 'သင့်ဖုန်းနံပါတ်ကို အတည်ပြုပါ',
    'otpTitleEmail': 'သင့် အီးမေးလ် OTP ကို အတည်ပြုပါ',
    'otpSentTo': 'ကုဒ် ပေးပို့သည့်နေရာ',
    'otpHint': 'ဂဏန်း ၆ လုံးပါ ကုဒ်ကို ရိုက်ထည့်ပါ။',
    'resendCode': 'ကုဒ် ပြန်ပို့ရန်',
    'resendIn': '{t} အကြာတွင် ပြန်ပို့နိုင်ပါမည်',
    'verify': 'အတည်ပြုရန်',
    'errOtp': 'ကုဒ် မမှန်ကန်ပါ။ ပြန်လည် စစ်ဆေးပါ။',

    'pinTitle': 'လုံခြုံရေး PIN သတ်မှတ်ပါ',
    'pinSubtitle': 'သင့် Wallet ကို ဖွင့်ရန် ဂဏန်း ၆ လုံးပါ PIN တစ်ခု ဖန်တီးပါ။',
    'pinConfirmTitle': 'PIN ကို ထပ်မံ ရိုက်ထည့်ပါ',
    'pinConfirmSubtitle': 'အတည်ပြုရန် PIN ကို နောက်တစ်ကြိမ် ရိုက်ထည့်ပါ။',
    'errPinMismatch': 'PIN နှစ်ခု မတူညီပါ။ ပြန်လည် ကြိုးစားပါ။',
    'errPinWeak': 'ခန့်မှန်းရ လွယ်ကူလွန်းပါသည်။ အခြား PIN တစ်ခု ရွေးချယ်ပါ။',
    'pinNeverShare': 'သင့် PIN ကို မည်သူ့ကိုမျှ မပြောပြပါနှင့်။',

    'readyTitle': 'သင့် Wallet အဆင်သင့် ဖြစ်ပါပြီ!',
    'readySubtitle':
        'အခြေခံ စာရင်းသွင်းမှု ပြီးဆုံးပါပြီ။ နောက်တစ်ဆင့်အဖြစ် သင့်လုံခြုံရေး သော့ကို ဖန်တီးပါမည်။',
    'readyStepEmail': 'အီးမေးလ်လိပ်စာ အတည်ပြုပြီး',
    'readyStepPin': 'လုံခြုံရေး PIN သတ်မှတ်ပြီး',
    'goToKeyPair': 'Key Pair သို့ သွားရန်',
    'goToWalletHome': 'Wallet Home သို့ သွားရန်',

    'keyIntroTitle': 'သင့် Wallet ကို လုံခြုံအောင် ပြုလုပ်ခြင်း',
    'keyIntroBody':
        'အထောက်အထားများ လက်ခံရယူရန် Holder Key Pair တစ်ခု ဖန်တီးရပါမည်။ ၎င်းသည် သင့်ဒစ်ဂျစ်တယ် လက်မှတ်ဖြစ်ပြီး အထောက်အထားကို သင်ပိုင်ဆိုင်ကြောင်း သက်သေပြပေးပါသည်။',
    'keyPointPrivate': 'Private Key သည် ဤဖုန်းထဲမှ ဘယ်တော့မှ ထွက်မသွားပါ။',
    'keyPointBinding': 'အထောက်အထားကို ဤသော့နှင့် တွဲချည်ထားပါသည် (PoP)။',
    'keyPointSign': 'တင်ပြသည့်အခါတိုင်း သင့်သော့ဖြင့် လက်မှတ်ရေးထိုးပါသည်။',
    'createKeyPair': 'Holder Key Pair ဖန်တီးရန်',
    'holderKey': 'Holder Key',
    'keyStatusNotCreated': 'မဖန်တီးရသေးပါ',
    'keyCreatedTitle': 'Holder Key Pair ဖန်တီးပြီးပါပြီ',
    'keyCreatedSubtitle':
        'သင့်သော့တွဲကို ဖုန်း၏ လုံခြုံသော Keystore အတွင်း သိမ်းဆည်းပြီးပါပြီ။',
    'keyType': 'သော့အမျိုးအစား',
    'keyCreated': 'ဖန်တီးသည့်နေ့',
    'keyStatus': 'အခြေအနေ',
    'keyActive': 'အသက်ဝင်နေသည်',
    'viewPublicKey': 'Public Key ကြည့်ရန်',
    'publicKey': 'Public Key (Base64)',
    'copied': 'ကူးယူပြီးပါပြီ',
    'copy': 'ကူးယူရန်',

    'getYourIdTitle': 'သင့် ဒစ်ဂျစ်တယ် မှတ်ပုံတင် ရယူပါ',
    'getYourIdSubtitle': 'အောက်ပါ အထောက်အထားကို ထုတ်ပေးသူထံမှ တောင်းခံပါမည်။',
    'credential': 'အထောက်အထား',
    'issuer': 'ထုတ်ပေးသူ',
    'whatYouGet': 'ပါဝင်မည့် အချက်အလက်များ',
    'whatYouGetHint':
        'ဤတန်ဖိုးများအတိုင်း ထုတ်ပေးသူက လက်မှတ်ရေးထိုး ထုတ်ပေးပါမည်။',
    'issuerVerified': 'အတည်ပြုပြီး ထုတ်ပေးသူ',
    'requestCredential': 'အထောက်အထား တောင်းခံရန်',
    'issuingTitle': 'သင့်အထောက်အထားကို ဖန်တီးနေပါသည်',
    'stepAuthorize': 'ထုတ်ပေးသူထံ ခွင့်ပြုချက် တောင်းခံခြင်း',
    'stepConsent': 'သင့်သဘောတူညီချက် ရယူခြင်း',
    'stepBindKey': 'Holder Public Key နှင့် တွဲချည်ခြင်း',
    'stepSign': 'ထုတ်ပေးသူ၏ သော့ဖြင့် လက်မှတ်ရေးထိုးခြင်း',
    'stepStore': 'Wallet အတွင်း လုံခြုံစွာ သိမ်းဆည်းခြင်း',
    'credentialIssued': 'အထောက်အထား ထုတ်ပေးပြီးပါပြီ',

    'scanTitle': 'ဘဏ်နှင့် အတည်ပြုရန် စကင်ဖတ်ပါ',
    'scanSubtitle': 'ဘဏ်၏ ဖန်သားပြင်ပေါ်ရှိ QR ကုဒ်ကို ဘောင်အတွင်း ချိန်ပါ။',
    'havingTrouble': 'အခက်အခဲ ရှိပါသလား?',
    'cameraPlaceholder': 'ကင်မရာ ကြည့်ကွင်း',
    'simulateScan': 'QR ကုဒ် ဖတ်ပြီးကြောင်း စမ်းသပ်ရန်',

    'reviewTitle': 'တောင်းဆိုမှုကို စစ်ဆေးပါ',
    'requestFrom': 'တောင်းဆိုသူ',
    'theyRequest': 'အောက်ပါ အချက်အလက်များကို တောင်းဆိုနေပါသည်',
    'viewDetails': 'အသေးစိတ် ကြည့်ရန်',
    'verifierVerified': 'အသိအမှတ်ပြု စစ်ဆေးသူ',

    'chooseCredentialTitle': 'အထောက်အထား ရွေးချယ်ပါ',
    'chooseCredentialSubtitle': 'တင်ပြရန် အထောက်အထားတစ်ခုကို ရွေးပါ။',
    'issuedBy': 'ထုတ်ပေးသူ',
    'credentialMatches': 'တောင်းဆိုထားသည့် အချက်အလက် အားလုံး ပါဝင်သည်',
    'credentialMissing': 'တောင်းဆိုထားသည့် အချက်အလက် အချို့ မပါဝင်ပါ',
    'validUntil': '{d} အထိ သက်တမ်းရှိသည်',

    'confirmShareTitle': 'အတည်ပြုပြီး မျှဝေပါ',
    'confirmShareSubtitle': 'အောက်ပါ အချက်အလက်များကို {v} သို့ ပေးပို့ပါမည်။',
    'consentText':
        'အထက်ပါ အချက်အလက်များကို {v} သို့ မျှဝေရန် ကျွန်ုပ် သဘောတူပါသည်။',
    'consentRequired': 'ဆက်လက် ဆောင်ရွက်ရန် သဘောတူညီချက် လိုအပ်ပါသည်။',
    'whatYouShare': 'မျှဝေမည့် အချက်အလက်များ',
    'sentSecurely': 'အချက်အလက်များကို ကုဒ်ဝှက်ပြီး လုံခြုံစွာ ပေးပို့ပါမည်။',

    'readingTitle': 'အချက်အလက် ဖတ်ယူနေသည်…',
    'readingSubtitle': 'Wallet မှ အချက်အလက်များကို လုံခြုံစွာ လက်ခံနေပါသည်။',
    'pleaseWait': 'ခဏစောင့်ပါ',

    'verifiedTitle': 'စစ်ဆေးမှု အောင်မြင်ပါသည်',
    'verifiedSubtitle': 'အထောက်အထားကို အောင်မြင်စွာ အတည်ပြုပြီးပါပြီ။',
    'verificationStatus': 'စစ်ဆေးမှု အခြေအနေ',
    'checkSignature': 'လက်မှတ် (Signature)',
    'checkIssuerCert': 'ထုတ်ပေးသူ လက်မှတ်',
    'checkDataIntegrity': 'အချက်အလက် ခိုင်မာမှု',
    'checkDeviceAuth': 'စက်ပစ္စည်း အတည်ပြုမှု',
    'checkRevocation': 'ပယ်ဖျက်မှု အခြေအနေ',
    'verifiedAt': 'စစ်ဆေးချိန်',
    'transactionId': 'လုပ်ဆောင်မှု အမှတ်',

    'attrFullName': 'အမည် အပြည့်အစုံ',
    'attrDob': 'မွေးသက္ကရာဇ်',
    'attrNationality': 'နိုင်ငံသား',
    'attrDocNumber': 'စာရွက်စာတမ်း အမှတ်',
    'attrExpiry': 'သက်တမ်းကုန်ဆုံးရက်',
    'attrAddress': 'နေရပ်လိပ်စာ',
    'attrPhoto': 'ဓာတ်ပုံ',

    'homeGreeting': 'မင်္ဂလာပါ',
    'homeProtected': 'ကာကွယ်ထားသည်',
    'recentActivity': 'မကြာသေးမီက မျှဝေမှုများ',
    'activityShared': 'အချက်အလက် {n} ခု မျှဝေခဲ့သည်',
    'activityEmpty': 'မျှဝေမှု မှတ်တမ်း မရှိသေးပါ။',
    'myCredentials': 'ကျွန်ုပ်၏ အထောက်အထားများ',
    'quickActions': 'အမြန် လုပ်ဆောင်ချက်များ',
    'actionScan': 'QR စကင်ဖတ်ရန်',
    'actionAdd': 'အထောက်အထား ထည့်ရန်',
    'actionSecurity': 'လုံခြုံရေး',
    'noCredentials': 'အထောက်အထား မရှိသေးပါ။',

    'credNationalId': 'အမျိုးသား မှတ်ပုံတင်',
    'credPassport': 'နိုင်ငံကူးလက်မှတ်',
    'credDriverLicense': 'ယာဉ်မောင်းလိုင်စင်',
    'issuerMoha': 'ပြည်ထဲရေးဝန်ကြီးဌာန',
    'issuerMofa': 'နိုင်ငံခြားရေးဝန်ကြီးဌာန',
    'nationalityMm': 'မြန်မာ',
  };

  // ═══════════════════════════════════════════════════════════════════════
  // English
  // ═══════════════════════════════════════════════════════════════════════
  static const Map<String, String> _en = {
    'appName': 'National Digital ID Wallet',
    'appNameShort': 'EID Wallet',
    'languageName': 'English',
    'continue': 'Continue',
    'back': 'Back',
    'next': 'Next',
    'cancel': 'Cancel',
    'done': 'Done',
    'close': 'Close',
    'decline': 'Decline',
    'share': 'Share',
    'skip': 'Skip',
    'change': 'Change',
    'needHelp': 'Need help?',
    'security': 'Security',
    'stepOf': 'Step {a} of {b}',

    'welcomeTitle': 'Welcome to the National Digital ID Wallet',
    'welcomeTitleAccent': 'Digital ID Wallet',
    'letsGetStarted': "Let's Get Started!",
    'issuedByGovernment':
        'Issued by the Government of the Republic of the Union of Myanmar',

    'authTabSignIn': 'Sign In',
    'authTabSignUp': 'Sign Up',
    'authSignInHeadline': 'Welcome back',
    'authSignInHeadlineSub': 'Sign in to manage your digital ID.',
    'authSignUpHeadline': 'Create your account',
    'authSignUpHeadlineSub': 'Fill in your details to get started.',
    'authSignUpDoneTitle': 'Account created',
    'authSignUpDoneBody': 'Your account is ready. Sign in to continue.',
    'fieldFullName': 'Full name',
    'fieldUidNumber': 'UID Number',
    'errUidNumber': 'Enter a valid UID number.',

    'registerMethodTitle': 'How would you like to register?',
    'registerMethodSubtitle':
        'Pick whichever is easiest for you, then enter your details.',
    'methodPhone': 'Phone Number',
    'methodPhoneDesc': 'We will send a one-time code by SMS.',
    'methodEmail': 'Email Address',
    'methodEmailDesc': 'We will send a one-time code to your inbox.',
    'methodUid': 'National UID',
    'methodUidDesc':
        'Register with your national ID number. We will match it against the government record.',
    'recommended': 'Recommended',
    'fieldPhone': 'Phone Number',
    'fieldEmail': 'Email Address',
    'fieldUid': 'UID Number',
    'hintUid': '12/ABC(N)123456',
    'errRequired': 'This field is required.',
    'errPhone': 'Enter a valid phone number.',
    'errEmail': 'Enter a valid email address.',
    'errUid': 'Invalid UID format. Example: 12/ABC(N)123456',

    'otpTitle': 'Verify your phone number',
    'otpTitleEmail': 'Verify your Email OTP',
    'otpSentTo': 'Code sent to',
    'otpHint': 'Enter the 6-digit code.',
    'resendCode': 'Resend code',
    'resendIn': 'Resend code in {t}',
    'verify': 'Verify',
    'errOtp': 'That code is not correct. Please check and try again.',

    'pinTitle': 'Set your Secure PIN',
    'pinSubtitle': 'Create a 6-digit PIN you will use to unlock your wallet.',
    'pinConfirmTitle': 'Re-enter your PIN',
    'pinConfirmSubtitle': 'Enter the PIN once more to confirm it.',
    'errPinMismatch': 'The two PINs do not match. Please try again.',
    'errPinWeak': 'That PIN is too easy to guess. Please choose another.',
    'pinNeverShare': 'Never share your PIN with anyone.',

    'readyTitle': 'Your Wallet is Ready!',
    'readySubtitle':
        'Basic registration is complete. Next we will create the security key that protects your credentials.',
    'readyStepEmail': 'Email address verified',
    'readyStepPin': 'Secure PIN created',
    'goToKeyPair': 'Go to Key Pair',
    'goToWalletHome': 'Go to Wallet Home',

    'keyIntroTitle': 'Securing your Wallet',
    'keyIntroBody':
        'To receive credentials, your wallet creates a Holder Key Pair. It acts as your digital signature and proves the credential belongs to you.',
    'keyPointPrivate': 'The private key never leaves this device.',
    'keyPointBinding':
        'Your credential is bound to this key (Proof of Possession).',
    'keyPointSign': 'Every presentation is signed with your key.',
    'createKeyPair': 'Create Holder Key Pair',
    'holderKey': 'Holder Key',
    'keyStatusNotCreated': 'Not created',
    'keyCreatedTitle': 'Holder Key Pair Created',
    'keyCreatedSubtitle':
        'Your key pair has been stored in this device’s secure keystore.',
    'keyType': 'Key type',
    'keyCreated': 'Created',
    'keyStatus': 'Status',
    'keyActive': 'Active',
    'viewPublicKey': 'View public key',
    'publicKey': 'Public key (Base64)',
    'copied': 'Copied to clipboard',
    'copy': 'Copy',

    'getYourIdTitle': 'Get your Digital ID',
    'getYourIdSubtitle': 'Request the following credential from the issuer.',
    'credential': 'Credential',
    'issuer': 'Issuer',
    'whatYouGet': 'What you will get',
    'whatYouGetHint':
        'These are the exact values the issuer will sign into your credential.',
    'issuerVerified': 'Verified issuer',
    'requestCredential': 'Request Credential',
    'issuingTitle': 'Creating your credential',
    'stepAuthorize': 'Requesting authorization from the issuer',
    'stepConsent': 'Capturing your consent',
    'stepBindKey': 'Binding to your Holder Public Key',
    'stepSign': 'Signing with the issuer key',
    'stepStore': 'Storing securely in your wallet',
    'credentialIssued': 'Credential Issued',

    'scanTitle': 'Scan to Verify with Bank',
    'scanSubtitle':
        'Line up the QR code on the bank’s screen inside the frame.',
    'havingTrouble': 'Having trouble?',
    'cameraPlaceholder': 'Camera viewfinder',
    'simulateScan': 'Simulate a successful scan',

    'reviewTitle': 'Verify Credential Request',
    'requestFrom': 'Request from',
    'theyRequest': 'They are requesting the following information',
    'viewDetails': 'View details',
    'verifierVerified': 'Verified requester',

    'chooseCredentialTitle': 'Choose Credential',
    'chooseCredentialSubtitle': 'Select the credential you want to present.',
    'issuedBy': 'Issued by',
    'credentialMatches': 'Has every requested detail',
    'credentialMissing': 'Missing some requested details',
    'validUntil': 'Valid until {d}',

    'confirmShareTitle': 'Confirm & Share',
    'confirmShareSubtitle': 'You are about to send the following to {v}.',
    'consentText': 'I agree to share the information above with {v}.',
    'consentRequired': 'Your consent is required to continue.',
    'whatYouShare': 'What you will share',
    'sentSecurely': 'Data will be encrypted and sent securely.',

    'readingTitle': 'Reading Data…',
    'readingSubtitle': 'Receiving data securely from the wallet.',
    'pleaseWait': 'Please wait',

    'verifiedTitle': 'Verification Successful',
    'verifiedSubtitle': 'The credential was verified successfully.',
    'verificationStatus': 'Verification status',
    'checkSignature': 'Signature',
    'checkIssuerCert': 'Issuer certificate',
    'checkDataIntegrity': 'Data integrity',
    'checkDeviceAuth': 'Device authentication',
    'checkRevocation': 'Revocation status',
    'verifiedAt': 'Verified at',
    'transactionId': 'Transaction ID',

    'attrFullName': 'Full Name',
    'attrDob': 'Date of Birth',
    'attrNationality': 'Nationality',
    'attrDocNumber': 'Document Number',
    'attrExpiry': 'Expiry Date',
    'attrAddress': 'Address',
    'attrPhoto': 'Photo',

    'homeGreeting': 'Hello',
    'homeProtected': 'Protected',
    'recentActivity': 'Recent shares',
    'activityShared': '{n} details shared',
    'activityEmpty': 'Nothing shared yet.',
    'myCredentials': 'My Credentials',
    'quickActions': 'Quick actions',
    'actionScan': 'Scan QR',
    'actionAdd': 'Add credential',
    'actionSecurity': 'Security',
    'noCredentials': 'No credentials yet.',

    'credNationalId': 'National ID Card',
    'credPassport': 'Passport',
    'credDriverLicense': 'Driver’s License',
    'issuerMoha': 'Ministry of Home Affairs',
    'issuerMofa': 'Ministry of Foreign Affairs',
    'nationalityMm': 'Myanmar',
  };
}

/// Delegate wiring [AppStrings] into the standard `Localizations` mechanism so
/// `AppStrings.of(context)` rebuilds automatically when the locale changes.
class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.supported.any((l) => l.languageCode == locale.languageCode);

  /// Returns a [SynchronousFuture] deliberately. The tables are compile-time
  /// constants, so there is nothing to await — and an async load would make
  /// `Localizations` render one empty frame every time the user flips the
  /// language switch, which shows up as a white flash on the Welcome screen.
  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture<AppStrings>(
        AppStrings.forLocale(isSupported(locale) ? locale : AppStrings.fallback),
      );

  @override
  bool shouldReload(AppStringsDelegate old) => false;
}
