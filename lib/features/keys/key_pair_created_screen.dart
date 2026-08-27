import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/success_check.dart';

/// Screen 8 — the outcome of creating the Holder Key Pair.
///
/// On success it shows the three facts a holder could ever need to quote to a
/// support desk — algorithm, creation date, status — and hides the raw public
/// key behind a disclosure. Nobody needs 120 characters of Base64 on a success
/// screen, but the one person who does needs it exactly right and copyable.
///
/// Key creation can also fail — a locked keystore, a device that will not
/// attest — so the failure outcome lives here too rather than in a dialog:
/// it is the same question ("did I get a key?") with the other answer, and it
/// owes the holder the same three things, one of which is now a reason.
///
/// **Tapping the mark swaps the two.** That is a review affordance, not a
/// feature: there is no way to make a real keystore refuse on demand, and both
/// outcomes have to be inspectable on a device before this ships.
class KeyPairCreatedScreen extends StatefulWidget {
  const KeyPairCreatedScreen({super.key});

  @override
  State<KeyPairCreatedScreen> createState() => _KeyPairCreatedScreenState();
}

class _KeyPairCreatedScreenState extends State<KeyPairCreatedScreen> {
  bool _showKey = false;
  bool _failed = false;

  void _swapOutcome() => setState(() => _failed = !_failed);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final key = WalletScope.of(context).holderKey;

    return AppScaffold(
      title: s.security,
      showBack: false,
      bottomBar: _failed
          ? PrimaryButton(
              label: s.tryAgain,
              icon: Icons.refresh_rounded,
              // Replaces rather than pushes: the screen the holder retries from
              // is the one they just came through, and a stack that grows one
              // pair of screens per attempt is a stack that lies about history.
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(Routes.keyCreate),
            )
          : PrimaryButton(
              label: s.getYourIdTitle,
              icon: Icons.badge_rounded,
              onPressed: () => _continueToIssuance(context),
            ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _failed ? _failedBody(s) : _createdBody(s, key),
      ),
    );
  }

  Widget _createdBody(AppStrings s, HolderKey? key) {
    return ListView(
      key: const ValueKey('created'),
      padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.xl),
      children: [
        Center(child: _OutcomeMark(onTap: _swapOutcome, child: SuccessCheck(size: 88))),
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
              _StatusRow(
                label: s.keyStatus,
                badge: StatusBadge(
                  label: s.keyActive,
                  icon: Icons.check_rounded,
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
    );
  }

  /// The same card, minus the two facts that do not exist: there is no key, so
  /// there is no algorithm and no creation time to show. What replaces them is
  /// the one fact the holder can act on — why it failed.
  Widget _failedBody(AppStrings s) {
    return ListView(
      key: const ValueKey('failed'),
      padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.xl),
      children: [
        Center(
          child: _OutcomeMark(
            onTap: _swapOutcome,
            child: const FailureCross(size: 88),
          ),
        ),
        Gap.h32,
        ScreenHeader(
          title: s.keyFailedTitle,
          subtitle: s.keyFailedSubtitle,
          align: CrossAxisAlignment.center,
        ),
        Gap.h32,

        AppCard(
          child: Column(
            children: [
              _StatusRow(
                label: s.keyStatus,
                badge: StatusBadge(
                  label: s.keyStatusNotCreated,
                  tone: BadgeTone.danger,
                  icon: Icons.close_rounded,
                ),
              ),
              const Divider(height: Gap.lg),
              KeyValueRow(label: s.reason, value: s.keyFailedReason),
            ],
          ),
        ),

        // No reassurance note here. The success page ends by promising the
        // private key never leaves the device; on a page where no key was
        // made, that promise is about nothing.
      ],
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

  /// `2026-08-27  09:11 AM`. The clock is 12-hour with the meridiem spelled
  /// out: this string is read back to a support desk, and `09:11` alone is
  /// ambiguous to anyone who does not think in 24-hour time.
  static String _formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final meridiem = d.hour < 12 ? 'AM' : 'PM';
    return '${d.year}-${two(d.month)}-${two(d.day)}  '
        '${two(hour)}:${two(d.minute)} $meridiem';
  }
}

/// The hero mark, made tappable so a reviewer can swap outcomes.
///
/// Transparent rather than decorated: the affordance is deliberately invisible.
/// A holder who taps the mark out of curiosity gets the other state and can tap
/// straight back, which costs them nothing — but a button drawn around it would
/// have to be explained, and there is nothing here to explain to them.
class _OutcomeMark extends StatelessWidget {
  const _OutcomeMark({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

/// A label with a badge for its value — the one row in the detail card whose
/// value is a state rather than a string.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.badge});

  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          badge,
        ],
      ),
    );
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
