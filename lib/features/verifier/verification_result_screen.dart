import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/success_check.dart';
import '../presentation/select_credential_screen.dart';

/// Screen 15 — verification result on the bank side.
///
/// Two audiences share this screen: the teller, who needs the identity fields,
/// and the auditor, who needs the four cryptographic checks and a transaction
/// id. Identity comes first at full size; the checks sit below in a compact
/// block that can be photographed or read out over the phone.
class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key, required this.args});

  final PresentationArgs args;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final credential = args.credential;
    final request = args.request;
    final now = DateTime.now();

    return AppScaffold(
      showBack: false,
      showLanguageToggle: false,
      title: request.verifierName,
      bottomBar: PrimaryButton(
        label: s.close,
        onPressed: () => Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.home, (route) => false),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xl),
        children: [
          const Center(child: SuccessCheck(size: 76)),
          Gap.h24,
          ScreenHeader(
            title: s.verifiedTitle,
            subtitle: s.verifiedSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,

          // ── Identity ────────────────────────────────────────────────────
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  credential.kind.label(s),
                  icon: credential.kind.icon,
                ),
                for (final claim in request.requestedClaims)
                  KeyValueRow(
                    label: claim.label(s),
                    value: credential.claims[claim] ?? '—',
                    numericValue: claim != ClaimId.fullName,
                  ),
                const Divider(height: Gap.xl),
                KeyValueRow(
                  label: s.issuer,
                  value: credential.issuerName(s),
                ),
              ],
            ),
          ),

          Gap.h16,

          // ── Cryptographic checks ────────────────────────────────────────
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(s.verificationStatus),
                _Check(label: s.checkSignature),
                _Check(label: s.checkIssuerCert),
                _Check(label: s.checkDataIntegrity),
                _Check(label: s.checkDeviceAuth),
                _Check(
                  label: s.checkRevocation,
                  // Offline proximity verification uses a cached status list,
                  // so this one is honest about being a cached result.
                  note: request.isProximity ? 'cached' : null,
                ),
              ],
            ),
          ),

          Gap.h16,

          // ── Audit trail ─────────────────────────────────────────────────
          AppCard(
            child: Column(
              children: [
                KeyValueRow(
                  label: s.verifiedAt,
                  value: _formatTimestamp(now),
                  numericValue: true,
                ),
                const Divider(height: Gap.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          s.transactionId,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Gap.w12,
                      Expanded(
                        flex: 6,
                        child: Text(
                          _transactionId(now),
                          textAlign: TextAlign.end,
                          style: AppTypography.mono(size: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Gap.h16,
          InfoNote(
            text: s.sentSecurely,
            icon: Icons.policy_outlined,
            tone: BadgeTone.success,
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// Deterministic stand-in for the verifier's own transaction reference.
  static String _transactionId(DateTime d) {
    final stamp = d.microsecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
    return '${stamp.substring(0, 4)}-${stamp.substring(4, 8)}'
        '-${stamp.substring(8)}-9d2e4a7d';
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.label, this.note});

  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontSize: 15),
            ),
          ),
          if (note != null) ...[
            Text(note!, style: Theme.of(context).textTheme.labelSmall),
            Gap.w8,
          ],
          const Icon(Icons.check_circle_rounded,
              size: 20, color: AppColors.success),
        ],
      ),
    );
  }
}
