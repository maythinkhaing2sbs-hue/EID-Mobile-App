import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';

/// Step 1 — choose how to register, and enter that identifier.
///
/// Method and identifier live on one screen because they are one decision: the
/// consequence of picking "Phone" is that you must supply a phone number, and
/// splitting that across two screens made the user confirm a choice before
/// seeing what it cost them. The field appears in place, directly under the
/// chosen card, so the connection is unmissable.
class RegistrationMethodScreen extends StatefulWidget {
  const RegistrationMethodScreen({super.key});

  @override
  State<RegistrationMethodScreen> createState() =>
      _RegistrationMethodScreenState();
}

class _RegistrationMethodScreenState extends State<RegistrationMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  RegistrationMethod? _selected;

  @override
  void initState() {
    super.initState();
    final draft = WalletScope.read(context).draft;
    _selected = draft.identifierFor(draft.method).isEmpty ? null : draft.method;
    if (_selected != null) _controller.text = draft.identifierFor(_selected!);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _select(RegistrationMethod method) {
    if (_selected == method) return;
    setState(() {
      _selected = method;
      _controller.clear();
    });
    // Drop focus straight into the field the choice just revealed.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  bool get _canContinue {
    final method = _selected;
    if (method == null) return false;
    return _validate(method, _controller.text) == null;
  }

  String? _validate(RegistrationMethod method, String? raw) {
    final s = AppStrings.of(context);
    final value = (raw ?? '').trim();
    if (value.isEmpty) return s.errRequired;

    return switch (method) {
      RegistrationMethod.phone =>
        Validators.isPhone(value) ? null : s.errPhone,
      RegistrationMethod.email =>
        Validators.isEmail(value) ? null : s.errEmail,
      RegistrationMethod.uid => Validators.isUid(value) ? null : s.errUid,
    };
  }

  void _continue() {
    final method = _selected;
    if (method == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    WalletScope.read(context).draft
      ..method = method
      ..setIdentifier(method, _controller.text.trim());

    Navigator.of(context).pushNamed(Routes.registerOtp);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      step: 1,
      totalSteps: 3,
      bottomBar: PrimaryButton(
        label: s.continueLabel,
        onPressed: _canContinue ? _continue : null,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
          children: [
            ScreenHeader(
              title: s.registerMethodTitle,
              subtitle: s.registerMethodSubtitle,
            ),
            Gap.h24,
            _MethodOption(
              method: RegistrationMethod.phone,
              icon: Icons.smartphone_rounded,
              title: s.methodPhone,
              subtitle: s.methodPhoneDesc,
              selected: _selected,
              onSelect: _select,
              field: _field(RegistrationMethod.phone),
            ),
            Gap.h12,
            _MethodOption(
              method: RegistrationMethod.email,
              icon: Icons.alternate_email_rounded,
              title: s.methodEmail,
              subtitle: s.methodEmailDesc,
              selected: _selected,
              onSelect: _select,
              field: _field(RegistrationMethod.email),
            ),
            Gap.h12,
            _MethodOption(
              method: RegistrationMethod.uid,
              icon: Icons.badge_outlined,
              title: s.methodUid,
              subtitle: s.methodUidDesc,
              badge: s.recommended,
              selected: _selected,
              onSelect: _select,
              field: _field(RegistrationMethod.uid),
            ),
            Gap.h24,
            InfoNote(text: s.sentSecurely, icon: Icons.shield_outlined),
          ],
        ),
      ),
    );
  }

  /// The input revealed under whichever card is selected.
  Widget _field(RegistrationMethod method) {
    final s = AppStrings.of(context);

    return switch (method) {
      RegistrationMethod.phone => AppTextField(
          controller: _controller,
          focusNode: _focus,
          label: s.fieldPhone,
          numeric: true,
          prefix: '+95 ',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
            LengthLimitingTextInputFormatter(15),
          ],
          onFieldSubmitted: (_) => _canContinue ? _continue() : null,
          validator: (v) => _validate(method, v),
        ),
      RegistrationMethod.email => AppTextField(
          controller: _controller,
          focusNode: _focus,
          label: s.fieldEmail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) => _canContinue ? _continue() : null,
          validator: (v) => _validate(method, v),
        ),
      RegistrationMethod.uid => AppTextField(
          controller: _controller,
          focusNode: _focus,
          label: s.fieldUid,
          hint: s.hintUid,
          numeric: true,
          textInputAction: TextInputAction.done,
          inputFormatters: [UidInputFormatter()],
          onFieldSubmitted: (_) => _canContinue ? _continue() : null,
          validator: (v) => _validate(method, v),
        ),
    };
  }
}

/// A method card that expands to reveal its own input when chosen.
class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.method,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
    required this.field,
    this.badge,
  });

  final RegistrationMethod method;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final RegistrationMethod? selected;
  final ValueChanged<RegistrationMethod> onSelect;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == method;

    return Column(
      children: [
        SelectionCard(
          icon: icon,
          title: title,
          subtitle: subtitle,
          badge: badge,
          selected: isSelected,
          onTap: () => onSelect(method),
        ),
        // Reveals with a size transition rather than appearing instantly, so
        // the eye follows the field down from the card that produced it.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: Gap.md),
                  child: field,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
