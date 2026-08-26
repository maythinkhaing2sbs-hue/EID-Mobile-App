import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 7 — explain and create the Holder Key Pair.
///
/// This is the one screen in the flow that has to teach a concept, so it earns
/// its explanation: what a key pair is, why the wallet needs one, and the three
/// guarantees that follow from it. The action stays a single button — the user
/// is not being asked to make a cryptographic choice, only to proceed.
class CreateKeyPairScreen extends StatefulWidget {
  const CreateKeyPairScreen({super.key});

  @override
  State<CreateKeyPairScreen> createState() => _CreateKeyPairScreenState();
}

class _CreateKeyPairScreenState extends State<CreateKeyPairScreen> {
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    await WalletScope.read(context).createHolderKey();
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushReplacementNamed(Routes.keyCreated);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return AppScaffold(
      title: s.security,
      bottomBar: PrimaryButton(
        label: s.createKeyPair,
        busy: _busy,
        onPressed: _create,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          Center(child: _KeyPairGraphic()),
          Gap.h32,
          ScreenHeader(title: s.keyIntroTitle, subtitle: s.keyIntroBody),
          Gap.h24,

          AppCard(
            child: Column(
              children: [
                _Point(icon: Icons.phonelink_lock_outlined, label: s.keyPointPrivate),
                const Divider(height: Gap.xl),
                _Point(icon: Icons.link_rounded, label: s.keyPointBinding),
                const Divider(height: Gap.xl),
                _Point(icon: Icons.draw_outlined, label: s.keyPointSign),
              ],
            ),
          ),

          Gap.h16,
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg, vertical: Gap.md),
            child: Row(
              children: [
                const Icon(Icons.vpn_key_outlined,
                    size: 20, color: AppColors.textTertiary),
                Gap.w12,
                Expanded(child: Text(s.holderKey, style: text.titleMedium)),
                StatusBadge(
                  label: s.keyStatusNotCreated,
                  tone: BadgeTone.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        Gap.w12,
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// Public / private key pair, drawn: two linked discs, one open and one sealed.
class _KeyPairGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Disc(
            icon: Icons.vpn_key_rounded,
            fill: AppColors.secondary,
            iconColor: AppColors.primary,
            caption: 'Public',
          ),
          Container(
            width: 34,
            height: 2,
            color: AppColors.borderStrong,
            margin: const EdgeInsets.only(bottom: 22),
          ),
          _Disc(
            icon: Icons.lock_rounded,
            fill: AppColors.primary,
            iconColor: Colors.white,
            caption: 'Private',
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({
    required this.icon,
    required this.fill,
    required this.iconColor,
    required this.caption,
  });

  final IconData icon;
  final Color fill;
  final Color iconColor;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 76,
          width: 76,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Icon(icon, size: 32, color: iconColor),
        ),
        Gap.h8,
        Text(caption, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
