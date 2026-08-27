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

  /// The credential request sitting with the issuer, if any. Null once it has
  /// been approved and the credential itself is in [credentials].
  CredentialRequest? pendingRequest;

  /// Completed presentations, newest first.
  final List<ActivityEntry> activity = [];

  bool get isRegistered => _pin != null;
  bool get hasHolderKey => holderKey != null;
  bool get hasPendingRequest => pendingRequest != null;

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
      WalletCredential.sampleNationalId.withClaims(_holderClaims);

  /// The passport the demo wallet is assumed to already hold, carrying the same
  /// holder details as the National ID.
  ///
  /// Nothing in these 15 screens issues a passport — it is the *second*
  /// document, and without one the presentation flow's "Choose Credential" step
  /// has nothing to choose between and the wallet home has nothing to page
  /// through.
  WalletCredential get holderPassport =>
      WalletCredential.samplePassport.withClaims(_holderClaims);

  /// Whatever the holder gave at registration, written over a sample record.
  /// Applied to every credential the wallet hands out so two documents can
  /// never disagree about whose they are.
  Map<ClaimId, String> get _holderClaims => {
        ClaimId.fullName: displayName,
        // Only written when the holder actually gave a Myanmar name: the sample
        // record already carries one, and overwriting it with an empty string
        // would blank the field rather than leave it alone.
        if (draft.nameMy.trim().isNotEmpty)
          ClaimId.myanmarName: draft.nameMy.trim(),
        if (draft.dateOfBirth case final dob?)
          ClaimId.dateOfBirth: _isoDate(dob),
      };

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Stand-in for the *deferred* end of OpenID4VCI: the request is accepted and
  /// the wallet is handed a transaction id, but the credential itself only
  /// comes back once the ministry has approved the application — days later.
  ///
  /// Re-running the flow returns the request already in flight rather than
  /// filing a second one: a holder who taps twice has one application, and a
  /// second reference number would be a second thing for a clerk to reconcile.
  CredentialRequest submitCredentialRequest() {
    final existing = pendingRequest;
    if (existing != null) return existing;

    final now = DateTime.now();
    final request = CredentialRequest(
      reference: CredentialRequest.referenceFor(now),
      kind: CredentialKind.nationalId,
      issuerKey: 'moha',
      submittedAt: now,
    );
    pendingRequest = request;
    notifyListeners();
    return request;
  }

  /// The issuer approving what was pending: the credential is signed and lands
  /// in the wallet, and the request stops being outstanding.
  ///
  /// In the shipped app this is driven by the notification that wakes the
  /// wallet days later, not by a button.
  Future<WalletCredential> approvePendingRequest() async {
    final credential = await issueCredential();
    pendingRequest = null;
    notifyListeners();
    return credential;
  }

  /// Stand-in for the OpenID4VCI authorization-code flow: authorize → token →
  /// credential request carrying the holder public key as proof of possession.
  Future<WalletCredential> issueCredential() async {
    final credential = pendingNationalId;
    _store(credential);
    // The passport arrives with it. It is not issued by this flow — see
    // [holderPassport] — but a wallet holding exactly one document turns every
    // later "choose a credential" step into a formality.
    _store(holderPassport);
    notifyListeners();
    return credential;
  }

  /// Adds a credential unless the wallet already holds that exact one, so a
  /// re-run of the issuance flow updates nothing and duplicates nothing.
  void _store(WalletCredential credential) {
    if (!credentials.any((c) => c.id == credential.id)) {
      credentials.add(credential);
    }
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
    pendingRequest = null;
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
