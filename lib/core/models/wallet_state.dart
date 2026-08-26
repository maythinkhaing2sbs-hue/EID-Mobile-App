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

  /// Stand-in for the OpenID4VCI authorization-code flow: authorize → token →
  /// credential request carrying the holder public key as proof of possession.
  Future<WalletCredential> issueCredential() async {
    const credential = WalletCredential.sampleNationalId;
    if (!credentials.any((c) => c.id == credential.id)) {
      credentials.add(credential);
    }
    notifyListeners();
    return credential;
  }

  /// Seeds a second credential so the "Choose Credential" screen has something
  /// to choose between.
  void seedDemoCredentials() {
    if (credentials.isEmpty) {
      credentials.addAll(const [
        WalletCredential.sampleNationalId,
        WalletCredential.samplePassport,
      ]);
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
