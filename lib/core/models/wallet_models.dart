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

  /// Where the OTP is sent — masked for display on the verification screen.
  String get otpTarget {
    if (method == RegistrationMethod.email && email.isNotEmpty) {
      return _maskEmail(email);
    }
    return phone.isEmpty ? '+95 9XX XXX XXX' : _maskPhone(phone);
  }

  static String _maskPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.length < 5) return value;
    final tail = digits.substring(digits.length - 3);
    return '${digits.substring(0, digits.length - 6)}XXX$tail';
  }

  static String _maskEmail(String value) {
    final at = value.indexOf('@');
    if (at <= 1) return value;
    return '${value[0]}${'*' * (at - 1)}${value.substring(at)}';
  }
}

enum RegistrationMethod { phone, email, uid }
