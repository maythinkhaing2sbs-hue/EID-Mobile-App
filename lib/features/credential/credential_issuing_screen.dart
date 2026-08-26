import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/success_check.dart';

/// The issuer-side half of screen 9: authorize → consent → bind key → sign →
/// store, then the issued credential.
///
/// Issuance takes real seconds and touches a government service, so the wait is
/// shown as named steps rather than a bare spinner. A user who is told what is
/// happening waits; a user watching an anonymous spinner force-quits.
class CredentialIssuingScreen extends StatefulWidget {
  const CredentialIssuingScreen({super.key});

  @override
  State<CredentialIssuingScreen> createState() =>
      _CredentialIssuingScreenState();
}

class _CredentialIssuingScreenState extends State<CredentialIssuingScreen> {
  int _current = 0;
  bool _issued = false;
  WalletCredential? _credential;

  static const _stepDurations = [
    Duration(milliseconds: 900),
    Duration(milliseconds: 700),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1100),
    Duration(milliseconds: 600),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    for (var i = 0; i < _stepDurations.length; i++) {
      await Future<void>.delayed(_stepDurations[i]);
      if (!mounted) return;
      setState(() => _current = i + 1);
    }

    final credential = await WalletScope.read(context).issueCredential();
    if (!mounted) return;
    setState(() {
      _issued = true;
      _credential = credential;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    final steps = [
      s.stepAuthorize,
      s.stepConsent,
      s.stepBindKey,
      s.stepSign,
      s.stepStore,
    ];

    if (_issued && _credential != null) {
      return _IssuedView(credential: _credential!);
    }

    return AppScaffold(
      showBack: false,
      showLanguageToggle: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: SizedBox(
              height: 56,
              width: 56,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          Gap.h32,
          ScreenHeader(
            title: s.issuingTitle,
            subtitle: s.pleaseWait,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++)
                  ProcessStep(
                    label: steps[i],
                    status: i < _current
                        ? StepStatus.done
                        : i == _current
                            ? StepStatus.active
                            : StepStatus.pending,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Credential Issued" — the credential itself, front and centre.
class _IssuedView extends StatelessWidget {
  const _IssuedView({required this.credential});

  final WalletCredential credential;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      showBack: false,
      bottomBar: PrimaryButton(
        label: s.goToWalletHome,
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.home, (route) => false),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.xl),
        children: [
          const Center(child: SuccessCheck(size: 80)),
          Gap.h24,
          ScreenHeader(
            title: s.credentialIssued,
            subtitle: s.readySubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          CredentialCard(credential: credential),
          Gap.h16,
          AppCard(
            child: Column(
              children: [
                KeyValueRow(
                  label: s.issuer,
                  value: credential.issuerName(s),
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.attrExpiry,
                  value: credential.validUntil,
                  numericValue: true,
                ),
              ],
            ),
          ),
          Gap.h16,
          InfoNote(text: s.keyPointBinding, icon: Icons.link_rounded),
        ],
      ),
    );
  }
}
