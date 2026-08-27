import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/success_check.dart';

/// Screen 8 — key pair created.
///
/// Shows the three facts a holder could ever need to quote to a support desk —
/// algorithm, creation date, status — and hides the raw public key behind a
/// disclosure. Nobody needs 120 characters of Base64 on a success screen, but
/// the one person who does needs it to be exactly correct and copyable.
class KeyPairCreatedScreen extends StatefulWidget {
  const KeyPairCreatedScreen({super.key});

  @override
  State<KeyPairCreatedScreen> createState() => _KeyPairCreatedScreenState();
}

class _KeyPairCreatedScreenState extends State<KeyPairCreatedScreen> {
  bool _showKey = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final key = WalletScope.of(context).holderKey;

    return AppScaffold(
      title: s.security,
      showBack: false,
      bottomBar: PrimaryButton(
        label: s.getYourIdTitle,
        icon: Icons.badge_rounded,
        onPressed: () => _continueToIssuance(context),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.xl),
        children: [
          Center(child: SuccessCheck(size: 88)),
          Gap.h32,
          ScreenHeader(
            title: s.keyCreatedTitle,
            subtitle: s.keyCreatedSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,

          AppCard(
            child: Column(
              children: [
                KeyValueRow(
                  label: s.keyType,
                  value: key?.algorithm ?? 'P-256 (ES256)',
                  numericValue: true,
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.keyCreated,
                  value: _formatDateTime(key?.createdAt ?? DateTime.now()),
                  numericValue: true,
                ),
                const Divider(height: Gap.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.keyStatus,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      StatusBadge(
                        label: s.keyActive,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Gap.h12,
          _PublicKeyDisclosure(
            expanded: _showKey,
            value: key?.publicKeyBase64 ?? '',
            onToggle: () => setState(() => _showKey = !_showKey),
          ),

          Gap.h16,
          InfoNote(text: s.keyPointPrivate),
        ],
      ),
    );
  }

  /// The key exists to bind a credential to this device, and the holder does
  /// not have one yet — so the button goes on to the issuance flow rather than
  /// dropping them on an empty Home to find it themselves.
  ///
  /// The registration stack behind this screen is torn down first: it must not
  /// be walkable. Home is rebuilt underneath so the issuance screen's back
  /// arrow has somewhere to go, and so leaving the flow lands where it should.
  void _continueToIssuance(BuildContext context) {
    Navigator.of(context)
      ..pushNamedAndRemoveUntil(Routes.home, (route) => false)
      ..pushNamed(Routes.credentialRequest);
  }

  static String _formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
  }
}

class _PublicKeyDisclosure extends StatelessWidget {
  const _PublicKeyDisclosure({
    required this.expanded,
    required this.value,
    required this.onToggle,
  });

  final bool expanded;
  final String value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const Icon(Icons.key_outlined,
                      size: 18, color: AppColors.primary),
                  Gap.w8,
                  Expanded(
                    child: Text(
                      expanded ? s.publicKey : s.viewPublicKey,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Gap.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSunken,
                      borderRadius: Radii.fieldAll,
                    ),
                    child: SelectableText(
                      value,
                      style: AppTypography.mono(size: 11),
                    ),
                  ),
                  Gap.h8,
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.copied)),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(s.copy),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
