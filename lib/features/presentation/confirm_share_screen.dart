import 'package:flutter/material.dart';

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
import '../../widgets/verifier_logo.dart';
import 'select_credential_screen.dart';

/// Screen 13 - final consent before anything leaves the device.
///
/// The screen is built around one sentence: *this document goes to that party,
/// over this protocol*. It is drawn as a transfer - the credential at the top,
/// the recipient at the bottom, an encrypted hop between them - because the
/// holder is not approving an abstract permission, they are approving a
/// movement of their own record to someone else.
///
/// The values themselves are printed, not just the claim names: this is the
/// last point at which the user can see that "Document Number" means their
/// actual NRC number. Consent is an explicit checkbox rather than an implied
/// button press, because under most data-protection regimes a button labelled
/// "Share" is not by itself a record of informed consent.
class ConfirmShareScreen extends StatefulWidget {
  const ConfirmShareScreen({super.key, required this.args});

  final PresentationArgs args;

  @override
  State<ConfirmShareScreen> createState() => _ConfirmShareScreenState();
}

class _ConfirmShareScreenState extends State<ConfirmShareScreen> {
  bool _consented = false;
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    // Wallet signs the vp_token with the holder key and POSTs it to
    // response_uri; the verifier screens take over from here.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Write the holder's own audit trail before handing off to the verifier:
    // this is the point at which data actually left the device.
    WalletScope.read(context).recordPresentation(
      verifierName: widget.args.request.verifierName,
      kind: widget.args.credential.kind,
      claimCount: widget.args.request.requestedClaims.length,
    );

    setState(() => _busy = false);
    Navigator.of(context).pushNamed(Routes.verifierReading,
        arguments: widget.args);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final request = widget.args.request;
    final credential = widget.args.credential;

    return AppScaffold(
      title: s.confirmShareTitle,
      bottomBar: ActionPair(
        secondary: SecondaryButton(
          label: s.back,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        primary: PrimaryButton(
          label: s.share,
          icon: Icons.lock_rounded,
          busy: _busy,
          onPressed: _consented ? _share : null,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.confirmShareTitle,
            subtitle: s.confirmShareSubtitle(request.verifierName),
          ),
          Gap.h24,

          _TransferCard(request: request, credential: credential),

          Gap.h16,
          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  s.whatYouShare,
                  trailing: FormatChip(label: credential.format),
                ),
                for (final (i, claim) in request.requestedClaims.indexed)
                  ClaimValueRow(
                    label: claim.label(s),
                    value: credential.claims[claim] ?? '-',
                    tabular: claim.isTabular,
                    first: i == 0,
                  ),
              ],
            ),
          ),

          Gap.h16,
          _ConsentBox(
            checked: _consented,
            label: s.consentText(request.verifierName),
            hint: s.consentRequired,
            onChanged: (v) => setState(() => _consented = v),
          ),

          Gap.h16,
          InfoNote(text: s.sentSecurely, icon: Icons.https_outlined),
        ],
      ),
    );
  }
}

/// The transfer itself: what is leaving, where it is going, and how.
///
/// Two nodes joined by a dashed hop rather than two separate cards. The gap
/// between them is where the encryption happens, and drawing it makes the
/// protocol line a property of the transfer instead of a footnote nobody
/// connects to anything.
class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.request, required this.credential});

  final PresentationRequest request;
  final WalletCredential credential;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FlowNode(
            leading: _CredentialTile(kind: credential.kind),
            title: credential.kind.label(s),
            subtitle: credential.issuerName(s),
          ),
          _Hop(
            label: request.isProximity
                ? 'ISO 18013-5 · offline'
                : 'OpenID4VP · HTTPS',
          ),
          _FlowNode(
            leading: VerifierLogo(
              name: request.verifierName,
              size: 44,
              onDark: false,
            ),
            title: request.verifierName,
            subtitle: request.verifierDomain,
            trailing: request.trusted
                ? const Icon(Icons.verified_rounded,
                    size: 18, color: AppColors.primary)
                : null,
          ),
        ],
      ),
    );
  }
}

/// One end of the transfer.
class _FlowNode extends StatelessWidget {
  const _FlowNode({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
        Gap.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              Gap.h4,
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[Gap.w8, trailing!],
      ],
    );
  }
}

/// The credential end of the transfer, in the brand gradient - the same tile
/// the wallet uses for a document it holds, so the top of the card is
/// recognisably *yours* and the bottom is recognisably someone else.
class _CredentialTile extends StatelessWidget {
  const _CredentialTile({required this.kind});

  final CredentialKind kind;

  IconData get _icon => switch (kind) {
        CredentialKind.passport => Icons.menu_book_rounded,
        CredentialKind.driverLicense => Icons.directions_car_rounded,
        CredentialKind.nationalId => Icons.badge_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: Radii.fieldAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(_icon, size: 22, color: AppColors.textOnPrimary),
    );
  }
}

/// The encrypted hop between the two nodes.
class _Hop extends StatelessWidget {
  const _Hop({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(
            width: 44,
            child: Center(
              child: CustomPaint(size: Size(9, 40), painter: _DashedHop()),
            ),
          ),
          Gap.w12,
          const Icon(Icons.lock_rounded,
              size: 13, color: AppColors.textTertiary),
          Gap.w4,
          Flexible(
            child: Text(
              label,
              style: AppTypography.mono(size: 11, color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashed line with an arrow head at the foot. Dashes rather than a solid
/// rule: the data is in flight here, and a solid line would read as a fixed
/// structural connection between two boxes.
class _DashedHop extends CustomPainter {
  const _DashedHop();

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    const dash = 4.0;
    const gap = 4.0;
    final lineEnd = size.height - 7;
    for (var y = 0.0; y < lineEnd; y += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, (y + dash).clamp(0.0, lineEnd)),
        paint,
      );
    }

    final head = Path()
      ..moveTo(x - size.width / 2, lineEnd - 1)
      ..lineTo(x, size.height)
      ..lineTo(x + size.width / 2, lineEnd - 1);
    canvas.drawPath(head, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_DashedHop oldDelegate) => false;
}

/// The consent gate.
///
/// A tick box, not a toggle and not an implied agreement: the whole card is
/// the tap target, the card turns green once given, and while it is empty the
/// reason the Share button is dead is printed underneath rather than left for
/// the user to work out.
class _ConsentBox extends StatelessWidget {
  const _ConsentBox({
    required this.checked,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final bool checked;
  final String label;
  final String hint;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: checked ? AppColors.successSurface : AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(
          color: checked ? AppColors.success : AppColors.border,
          width: checked ? 1.6 : 1,
        ),
        boxShadow: checked ? null : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!checked),
          borderRadius: Radii.cardAll,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.lg, Gap.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: checked,
                      onChanged: (v) => onChanged(v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.success
                            : Colors.transparent,
                      ),
                      side: BorderSide(
                        color: checked
                            ? AppColors.success
                            : AppColors.borderStrong,
                        width: 1.6,
                      ),
                    ),
                    Gap.w12,
                    Expanded(
                      child: Text(
                        label,
                        style: text.bodyLarge?.copyWith(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!checked) ...[
                  Gap.h8,
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(hint, style: text.labelSmall),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
