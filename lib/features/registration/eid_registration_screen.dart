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

/// Screen 3 — EID registration data entry.
///
/// The name is captured twice, Myanmar and English, because that is how it
/// appears on the physical card and both forms end up as claims in the issued
/// credential. Validation runs per field on interaction so the user fixes
/// mistakes as they go rather than meeting six errors at the end.
class EidRegistrationScreen extends StatefulWidget {
  const EidRegistrationScreen({super.key});

  @override
  State<EidRegistrationScreen> createState() => _EidRegistrationScreenState();
}

class _EidRegistrationScreenState extends State<EidRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameMy = TextEditingController();
  final _nameEn = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _uid = TextEditingController();
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    // Restore anything already captured, so Back never loses typing.
    final draft = WalletScope.read(context).draft;
    _nameMy.text = draft.nameMy;
    _nameEn.text = draft.nameEn;
    _phone.text = draft.phone;
    _email.text = draft.email;
    _uid.text = draft.uid;
    _dob = draft.dateOfBirth;
  }

  @override
  void dispose() {
    _nameMy.dispose();
    _nameEn.dispose();
    _phone.dispose();
    _email.dispose();
    _uid.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = WalletScope.read(context).draft
      ..nameMy = _nameMy.text.trim()
      ..nameEn = _nameEn.text.trim()
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..uid = _uid.text.trim()
      ..dateOfBirth = _dob;

    // Whichever channel was chosen, the OTP goes there.
    if (draft.method == RegistrationMethod.email && draft.email.isEmpty) {
      draft.method = RegistrationMethod.phone;
    }

    Navigator.of(context).pushNamed(Routes.registerOtp);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return AppScaffold(
      step: 2,
      totalSteps: 4,
      bottomBar: PrimaryButton(label: s.next, onPressed: _submit),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
          children: [
            ScreenHeader(title: s.eidRegTitle, subtitle: s.eidRegSubtitle),
            Gap.h24,

            AppTextField(
              controller: _nameMy,
              label: s.fieldNameMy,
              hint: s.hintNameMy,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.errRequired : null,
            ),
            Gap.h16,
            AppTextField(
              controller: _nameEn,
              label: s.fieldNameEn,
              hint: s.hintNameEn,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.errRequired;
                if (!Validators.isLatinName(v)) return s.errNameEn;
                return null;
              },
            ),
            Gap.h16,
            DateField(
              label: s.fieldDob,
              value: _dob,
              hint: s.selectDate,
              onChanged: (d) => setState(() => _dob = d),
              validator: (d) => d == null ? s.errRequired : null,
            ),
            Gap.h16,
            AppTextField(
              controller: _phone,
              label: s.fieldPhone,
              numeric: true,
              prefix: '+95 ',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
                LengthLimitingTextInputFormatter(15),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.errRequired;
                if (!Validators.isPhone(v)) return s.errPhone;
                return null;
              },
            ),
            Gap.h16,
            AppTextField(
              controller: _email,
              label: s.fieldEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.errRequired;
                if (!Validators.isEmail(v)) return s.errEmail;
                return null;
              },
            ),
            Gap.h16,
            AppTextField(
              controller: _uid,
              label: s.fieldUid,
              hint: s.hintUid,
              numeric: true,
              textInputAction: TextInputAction.done,
              inputFormatters: [UidInputFormatter()],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return s.errRequired;
                if (!Validators.isUid(v)) return s.errUid;
                return null;
              },
            ),

            Gap.h24,
            InfoNote(text: s.sentSecurely, icon: Icons.shield_outlined),
          ],
        ),
      ),
    );
  }
}
