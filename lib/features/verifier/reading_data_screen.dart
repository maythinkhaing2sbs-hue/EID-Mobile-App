import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../presentation/select_credential_screen.dart';

/// Screen 14 — the bank app receiving data.
///
/// This screen belongs to the *verifier*, so the chrome deliberately changes:
/// no wallet branding, no back button, no language toggle. The user should feel
/// they have handed off to another party's app, which is exactly what happened.
class ReadingDataScreen extends StatefulWidget {
  const ReadingDataScreen({super.key, required this.args});

  final PresentationArgs args;

  @override
  State<ReadingDataScreen> createState() => _ReadingDataScreenState();
}

class _ReadingDataScreenState extends State<ReadingDataScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _advance();
  }

  Future<void> _advance() async {
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(Routes.verifierResult, arguments: widget.args);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      showBack: false,
      showLanguageToggle: false,
      title: widget.args.request.verifierName,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => CustomPaint(
                painter: _PulsePainter(progress: _pulse.value),
                child: child,
              ),
              child: const Center(
                child: Icon(Icons.wifi_tethering_rounded,
                    size: 44, color: AppColors.primary),
              ),
            ),
          ),
          Gap.h32,
          ScreenHeader(
            title: s.readingTitle,
            subtitle: s.readingSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,
          const SizedBox(
            width: 180,
            child: LinearProgressIndicator(minHeight: 4),
          ),
        ],
      ),
    );
  }
}

/// Three concentric rings expanding outward on a stagger — reads as "data
/// arriving" without needing a literal spinner.
class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final maxR = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final r = maxR * (0.34 + 0.66 * t);
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.primary.withValues(alpha: (1 - t) * 0.45),
      );
    }

    canvas.drawCircle(
      centre,
      maxR * 0.32,
      Paint()..color = AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}
