import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/scanner_frame.dart';

/// Screen 10 — scan the verifier's QR code.
///
/// Full-bleed dark screen: the viewfinder is the interface, so all chrome is
/// stripped back to a translucent bar and one help link. The camera preview
/// itself is the only integration point left open — drop a scanner plugin's
/// preview widget into [ScannerFrame.preview] and forward its detection to
/// [_onDetected].
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  /// Called with the decoded `openid4vp://` request URI. In this build the
  /// request is the sample bank KYC one; a real scanner passes the parsed
  /// Authorization Request through instead.
  void _onDetected([String? _]) {
    if (_handled) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacementNamed(
      Routes.presentReview,
      arguments: PresentationRequest.sampleBankKyc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF10161F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          s.scanTitle,
          style: text.titleMedium?.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ScannerFrame(
        caption: Column(
          children: [
            Text(
              s.scanSubtitle,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: Colors.white70),
            ),
            Gap.h24,
            // Stands in for a detection event until a camera plugin is wired
            // up; remove once the scanner is live.
            OutlinedButton(
              onPressed: _onDetected,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
              ),
              child: Text(s.simulateScan),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Gap.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: AppColors.surface,
                  builder: (_) => const _TroubleSheet(),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 18),
                label: Text(s.havingTrouble),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TroubleSheet extends StatelessWidget {
  const _TroubleSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.havingTrouble, style: text.titleLarge),
            Gap.h16,
            _Tip(icon: Icons.light_mode_outlined, text: s.scanSubtitle),
            _Tip(icon: Icons.wifi_rounded, text: s.sentSecurely),
            _Tip(icon: Icons.support_agent_rounded, text: s.needHelp),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          Gap.w12,
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
