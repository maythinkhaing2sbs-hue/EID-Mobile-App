import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Screen 2 — how would you like to register?
///
/// Three equal-weight cards rather than a radio list: each option carries a
/// one-line consequence ("we will send a code by SMS"), which is the actual
/// decision the user is making. Choosing National UID routes straight to the
/// full EID form; phone and email go to the short path.
class RegistrationMethodScreen extends StatefulWidget {
  const RegistrationMethodScreen({super.key});

  @override
  State<RegistrationMethodScreen> createState() =>
      _RegistrationMethodScreenState();
}

class _RegistrationMethodScreenState extends State<RegistrationMethodScreen> {
  RegistrationMethod? _selected;

  void _continue() {
    final method = _selected;
    if (method == null) return;
    WalletScope.read(context).draft.method = method;
    Navigator.of(context).pushNamed(Routes.registerEid);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      step: 1,
      totalSteps: 4,
      bottomBar: PrimaryButton(
        label: s.continueLabel,
        onPressed: _selected == null ? null : _continue,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.registerMethodTitle,
            subtitle: s.registerMethodSubtitle,
          ),
          Gap.h24,
          SelectionCard(
            icon: Icons.smartphone_rounded,
            title: s.methodPhone,
            subtitle: s.methodPhoneDesc,
            selected: _selected == RegistrationMethod.phone,
            onTap: () =>
                setState(() => _selected = RegistrationMethod.phone),
          ),
          Gap.h12,
          SelectionCard(
            icon: Icons.alternate_email_rounded,
            title: s.methodEmail,
            subtitle: s.methodEmailDesc,
            selected: _selected == RegistrationMethod.email,
            onTap: () =>
                setState(() => _selected = RegistrationMethod.email),
          ),
          Gap.h12,
          SelectionCard(
            icon: Icons.badge_outlined,
            title: s.methodUid,
            subtitle: s.methodUidDesc,
            badge: s.recommended,
            selected: _selected == RegistrationMethod.uid,
            onTap: () => setState(() => _selected = RegistrationMethod.uid),
          ),
        ],
      ),
    );
  }
}
