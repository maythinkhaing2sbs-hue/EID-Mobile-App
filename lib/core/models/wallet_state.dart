import 'package:flutter/widgets.dart';

import 'wallet_models.dart';

/// In-memory wallet session.
///
/// This is deliberately a plain [ChangeNotifier] with no persistence: it models
/// the *UI* state the 15 designed screens move through. The real app swaps the
/// bodies of [createHolderKey] / [issueCredential] / [presentCredential] for
/// platform keystore + OpenID4VCI / OpenID4VP calls; the screens do not change.
class WalletState extends ChangeNotifier {
  RegistrationDraft draft = RegistrationDraft();

  String? _pin;
  bool biometricsEnabled = false;
  HolderKey? holderKey;
  final List<WalletCredential> credentials = [];

  /// Completed presentations, newest first.
  final List<ActivityEntry> activity = [];

  bool get isRegistered => _pin != null;
  bool get hasHolderKey => holderKey != null;

  String get displayName {
    if (draft.nameEn.trim().isNotEmpty) return draft.nameEn.trim();
    if (draft.nameMy.trim().isNotEmpty) return draft.nameMy.trim();
    return 'Aung Ko Ko';
  }

  void setPin(String pin) {
    _pin = pin;
    notifyListeners();
  }

  bool verifyPin(String pin) => _pin == pin;

  void setBiometrics(bool enabled) {
    biometricsEnabled = enabled;
    notifyListeners();
  }

  /// Stand-in for `SecureKeyStore.generateKeyPair(alg: ES256)`. The private key
  /// would be generated inside the Android Keystore / iOS Secure Enclave and
  /// never surfaced to Dart — only the public key comes back.
  Future<HolderKey> createHolderKey() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final key = HolderKey.demo(DateTime.now());
    holderKey = key;
    notifyListeners();
    return key;
  }

  /// The National ID exactly as it will be issued, with whatever the holder
  /// gave at registration written over the sample record. The request screen
  /// previews *this* object and [issueCredential] stores it, so what the user
  /// approves and what lands in the wallet can never disagree.
  WalletCredential get pendingNationalId =>
      WalletCredential.sampleNationalId.withClaims({
        ClaimId.fullName: displayName,
        if (draft.dateOfBirth case final dob?)
          ClaimId.dateOfBirth: _isoDate(dob),
      });

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Stand-in for the OpenID4VCI authorization-code flow: authorize → token →
  /// credential request carrying the holder public key as proof of possession.
  Future<WalletCredential> issueCredential() async {
    final credential = pendingNationalId;
    if (!credentials.any((c) => c.id == credential.id)) {
      credentials.add(credential);
    }
    notifyListeners();
    return credential;
  }

  /// Records a completed presentation on the holder's own audit trail.
  void recordPresentation({
    required String verifierName,
    required CredentialKind kind,
    required int claimCount,
  }) {
    activity.insert(
      0,
      ActivityEntry(
        verifierName: verifierName,
        kind: kind,
        claimCount: claimCount,
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Seeds a second credential so the "Choose Credential" screen has something
  /// to choose between.
  void seedDemoCredentials() {
    if (credentials.isEmpty) {
      credentials.addAll(const [
        WalletCredential.sampleNationalId,
        WalletCredential.samplePassport,
      ]);
      // There is no biometric enrolment screen in the flow, so nothing else
      // would ever set this — and the unlock keypad would never offer its
      // biometric key. The demo session opts in on the user's behalf.
      biometricsEnabled = true;
      // A wallet seeded with credentials it never received should also carry
      // the history it never made, or the home screen's activity list reads as
      // broken rather than empty.
      activity.addAll(ActivityEntry.samples);
      notifyListeners();
    }
  }

  void reset() {
    draft = RegistrationDraft();
    _pin = null;
    biometricsEnabled = false;
    holderKey = null;
    credentials.clear();
    notifyListeners();
  }
}

class WalletScope extends InheritedNotifier<WalletState> {
  const WalletScope({
    super.key,
    required WalletState state,
    required super.child,
  }) : super(notifier: state);

  static WalletState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WalletScope>()!.notifier!;

  static WalletState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<WalletScope>()!.notifier!;
}
