import '../l10n/app_strings.dart';

/// The claims a credential can carry. Using an enum rather than free strings
/// means a verifier request, a consent screen and a credential can never drift
/// apart on spelling, and every label is localised in exactly one place.
enum ClaimId {
  fullName,
  dateOfBirth,
  nationality,
  documentNumber,
  expiryDate,
  address,
  photo;

  String label(AppStrings s) => switch (this) {
        ClaimId.fullName => s.attrFullName,
        ClaimId.dateOfBirth => s.attrDob,
        ClaimId.nationality => s.attrNationality,
        ClaimId.documentNumber => s.attrDocNumber,
        ClaimId.expiryDate => s.attrExpiry,
        ClaimId.address => s.attrAddress,
        ClaimId.photo => s.attrPhoto,
      };

  /// Whether the value belongs in the tabular-figure face.
  ///
  /// Codes, numbers and ISO dates line up in a column that way; names and free
  /// text stay in the body face. It lives on the claim itself so every screen
  /// that prints a value renders it identically — the issuance preview and the
  /// verifier consent screens have to agree, or the same record reads as two.
  bool get isTabular => switch (this) {
        ClaimId.dateOfBirth ||
        ClaimId.nationality ||
        ClaimId.documentNumber ||
        ClaimId.expiryDate =>
          true,
        ClaimId.fullName || ClaimId.address || ClaimId.photo => false,
      };
}

enum CredentialKind {
  nationalId,
  passport,
  driverLicense;

  String label(AppStrings s) => switch (this) {
        CredentialKind.nationalId => s.credNationalId,
        CredentialKind.passport => s.credPassport,
        CredentialKind.driverLicense => s.credDriverLicense,
      };
}

/// A credential as it sits in the wallet after OpenID4VCI issuance.
class WalletCredential {
  const WalletCredential({
    required this.id,
    required this.kind,
    required this.issuerKey,
    required this.validUntil,
    required this.claims,
    this.format = 'SD-JWT VC',
  });

  final String id;
  final CredentialKind kind;

  /// `'moha'` / `'mofa'` — resolved to a localised ministry name at render time.
  final String issuerKey;
  final String validUntil;
  final String format;

  /// Claim values are stored raw; only the *labels* are localised.
  final Map<ClaimId, String> claims;

  String issuerName(AppStrings s) =>
      issuerKey == 'mofa' ? s.issuerMofa : s.issuerMoha;

  /// The same credential with some claim values replaced.
  ///
  /// Issuance is previewed before it happens, so the request screen and the
  /// stored credential have to be built from one object — otherwise the values
  /// the holder consented to and the values that land in the wallet can drift.
  WalletCredential withClaims(Map<ClaimId, String> overrides) =>
      WalletCredential(
        id: id,
        kind: kind,
        issuerKey: issuerKey,
        validUntil: validUntil,
        format: format,
        claims: {...claims, ...overrides},
      );

  static const WalletCredential sampleNationalId = WalletCredential(
    id: 'urn:uuid:3978344f-8596-4c3a-a978-8fcaba3903c5',
    kind: CredentialKind.nationalId,
    issuerKey: 'moha',
    validUntil: '2030-12-31',
    claims: {
      ClaimId.fullName: 'Aung Ko Ko',
      ClaimId.dateOfBirth: '1990-05-15',
      ClaimId.nationality: 'MMR',
      ClaimId.documentNumber: '12/ABC(N)123456',
      ClaimId.expiryDate: '2030-12-31',
    },
  );

  static const WalletCredential samplePassport = WalletCredential(
    id: 'urn:uuid:9c2a1f77-1d43-40f8-9d10-2b7f6b18e0a1',
    kind: CredentialKind.passport,
    issuerKey: 'mofa',
    validUntil: '2029-06-30',
    format: 'ISO 18013-5 mdoc',
    claims: {
      ClaimId.fullName: 'Aung Ko Ko',
      ClaimId.dateOfBirth: '1990-05-15',
      ClaimId.nationality: 'MMR',
      ClaimId.documentNumber: 'MB1234567',
      ClaimId.expiryDate: '2029-06-30',
    },
  );
}

/// An OpenID4VP authorization request, reduced to what the consent screens
/// actually need to show the holder.
class PresentationRequest {
  const PresentationRequest({
    required this.verifierName,
    required this.verifierDomain,
    required this.requestedClaims,
    this.isProximity = false,
    this.trusted = true,
  });

  final String verifierName;
  final String verifierDomain;
  final List<ClaimId> requestedClaims;

  /// True for the ISO 18013-5 offline flow, which has no `response_uri`.
  final bool isProximity;

  /// Whether the verifier resolved against the trust registry.
  final bool trusted;

  static const PresentationRequest sampleBankKyc = PresentationRequest(
    verifierName: 'ABC Bank',
    verifierDomain: 'abc-bank.com',
    requestedClaims: [
      ClaimId.fullName,
      ClaimId.dateOfBirth,
      ClaimId.nationality,
      ClaimId.documentNumber,
      ClaimId.expiryDate,
    ],
  );
}

/// One completed presentation: who received data, from which credential, and
/// how much of it.
///
/// A wallet that holds a citizen's identity owes them a record of where it has
/// been sent. This is the holder's side of the audit trail the verifier keeps.
class ActivityEntry {
  const ActivityEntry({
    required this.verifierName,
    required this.kind,
    required this.claimCount,
    required this.at,
  });

  final String verifierName;
  final CredentialKind kind;
  final int claimCount;
  final DateTime at;

  /// `2026-08-24`. Absolute rather than "2 days ago": relative time needs
  /// plural rules in both languages, and a date is what a citizen would quote
  /// when querying a share they did not recognise.
  String get date =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  /// Fixed dates, not `DateTime.now()` offsets — seeded demo rows that move
  /// every run make the screenshot previews churn for no reason.
  static final List<ActivityEntry> samples = [
    ActivityEntry(
      verifierName: 'ABC Bank',
      kind: CredentialKind.nationalId,
      claimCount: 5,
      at: DateTime(2026, 8, 24),
    ),
    ActivityEntry(
      verifierName: 'Yangon General Hospital',
      kind: CredentialKind.nationalId,
      claimCount: 3,
      at: DateTime(2026, 8, 19),
    ),
  ];
}

/// The device-bound P-256 key pair created in step 7 and confirmed in step 8.
class HolderKey {
  const HolderKey({
    required this.algorithm,
    required this.createdAt,
    required this.publicKeyBase64,
  });

  final String algorithm;
  final DateTime createdAt;
  final String publicKeyBase64;

  static HolderKey demo(DateTime now) => HolderKey(
        algorithm: 'P-256 (ES256)',
        createdAt: now,
        publicKeyBase64:
            'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEqL8mPz3fVX5t2vJ9y1H0oQ'
            'Wz7bK4nR6cUeA1sMdT9gYh2XkPq0LrN8vBcE3wZaFmJi7uOy4pSdHgKlT2b'
            'x91zQ==',
      );
}

/// Everything the registration form collects before the OTP step.
class RegistrationDraft {
  RegistrationDraft({
    this.nameMy = '',
    this.nameEn = '',
    this.dateOfBirth,
    this.phone = '',
    this.email = '',
    this.uid = '',
    this.method = RegistrationMethod.phone,
  });

  String nameMy;
  String nameEn;
  DateTime? dateOfBirth;
  String phone;
  String email;
  String uid;
  RegistrationMethod method;

  /// The value captured for a given registration method.
  String identifierFor(RegistrationMethod method) => switch (method) {
        RegistrationMethod.phone => phone,
        RegistrationMethod.email => email,
        RegistrationMethod.uid => uid,
      };

  void setIdentifier(RegistrationMethod method, String value) {
    switch (method) {
      case RegistrationMethod.phone:
        phone = value;
      case RegistrationMethod.email:
        email = value;
      case RegistrationMethod.uid:
        uid = value;
    }
  }

  /// Registering by UID sends the code to whatever number the government has
  /// on file, which this app does not know — so the screen says exactly that
  /// rather than inventing a masked number.
  bool get otpGoesToRecordedNumber => method == RegistrationMethod.uid;

  /// Where the OTP is sent — masked for display on the verification screen.
  String get otpTarget => switch (method) {
        RegistrationMethod.email =>
          email.isEmpty ? '—' : maskEmail(email),
        RegistrationMethod.phone =>
          phone.isEmpty ? '+95 9•• ••• •••' : maskPhone(phone),
        RegistrationMethod.uid => uid.isEmpty ? '—' : uid,
      };

  /// Hides the middle of a phone number while preserving its length.
  ///
  /// Length matters: a mask that drops digits shows the user a number that is
  /// not theirs, and they cannot tell whether the app has the right one. Every
  /// hidden digit is replaced one-for-one.
  static String maskPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '+95 $digits';

    const headLength = 2;
    const tailLength = 3;
    final head = digits.substring(0, headLength);
    final tail = digits.substring(digits.length - tailLength);
    final hidden = '•' * (digits.length - headLength - tailLength);
    return '+95 $head$hidden$tail';
  }

  /// `aung.ko@example.com` → `a•••••@example.com`. The domain stays visible so
  /// the user can spot a typo in the part that decides where mail lands.
  static String maskEmail(String value) {
    final at = value.indexOf('@');
    if (at <= 1) return value;
    return '${value[0]}${'•' * (at - 1)}${value.substring(at)}';
  }
}

enum RegistrationMethod { phone, email, uid }
