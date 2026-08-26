import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import 'select_credential_screen.dart';

/// Screen 13 — final consent before anything leaves the device.
///
/// The values themselves are shown here, not just the claim names: this is the
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

          AppCard(
            padding: Insets.cardLoose,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(credential.kind.label(s)),
                for (final claim in request.requestedClaims)
                  ClaimRow(
                    label: claim.label(s),
                    value: credential.claims[claim],
                  ),
              ],
            ),
          ),

          Gap.h16,
          _ConsentBox(
            checked: _consented,
            label: s.consentText(request.verifierName),
            onChanged: (v) => setState(() => _consented = v),
          ),

          Gap.h16,
          InfoNote(text: s.sentSecurely, icon: Icons.https_outlined),
        ],
      ),
    );
  }
}

class _ConsentBox extends StatelessWidget {
  const _ConsentBox({
    required this.checked,
    required this.label,
    required this.onChanged,
  });

  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: checked ? AppColors.successSurface : AppColors.surface,
      borderColor: checked ? AppColors.success : AppColors.border,
      padding: const EdgeInsets.symmetric(
          horizontal: Gap.md, vertical: Gap.sm),
      onTap: () => onChanged(!checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: checked,
            onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Gap.w8,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.md),
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
