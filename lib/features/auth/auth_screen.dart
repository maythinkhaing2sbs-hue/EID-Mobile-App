import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/segmented_tabs.dart';

enum AuthMode { signIn, signUp }

/// Screen 1b — sign in / create account.
///
/// One screen with a segmented control rather than two routes: the two forms
/// differ by a single field, and a citizen who taps the wrong one should be
/// able to correct it without losing what they have already typed. The
/// controllers below are shared across both modes for exactly that reason —
/// switching tabs keeps the email, phone and UID intact.
///
/// Both forms ask for email, phone *and* UID. That is heavier than a
/// conventional login, and deliberately so: this is a government identity
/// wallet, and the three together are what the issuer matches against the
/// national register.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.signIn});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

  /// One key per mode. A single shared key would carry the previous form's
  /// error state across a tab switch and light up fields the user has not
  /// touched yet.
  final Map<AuthMode, GlobalKey<FormState>> _formKeys = {
    AuthMode.signIn: GlobalKey<FormState>(),
    AuthMode.signUp: GlobalKey<FormState>(),
  };

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _uid = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restore anything already captured, so Back never loses typing.
    final draft = WalletScope.read(context).draft;
    _name.text = draft.nameEn.isNotEmpty ? draft.nameEn : draft.nameMy;
    _email.text = draft.email;
    _phone.text = draft.phone;
    _uid.text = draft.uid;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _uid.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == AuthMode.signUp;

  void _switchTo(AuthMode mode) {
    if (mode == _mode) return;
    FocusScope.of(context).unfocus();
    setState(() => _mode = mode);
  }

  void _submit() {
    if (!(_formKeys[_mode]!.currentState?.validate() ?? false)) return;

    final draft = WalletScope.read(context).draft
      ..email = _email.text.trim()
      ..phone = _phone.text.trim()
      ..uid = _uid.text.trim();

    if (_isSignUp) {
      // The card carries the name in both scripts. Which slot a single entry
      // belongs in is decided by the script it was typed in, so a Myanmar name
      // never lands in the Latin field and vice versa.
      final name = _name.text.trim();
      if (Validators.isLatinName(name)) {
        draft.nameEn = name;
      } else {
        draft.nameMy = name;
      }

      // New account: verify the channel, then set up PIN and biometrics.
      Navigator.of(context).pushNamed(Routes.registerOtp);
    } else {
      // Returning holder: the wallet already exists, so go straight to the
      // unlock gate rather than back through registration.
      Navigator.of(context).pushNamed(Routes.unlock);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, Gap.xs, Gap.md, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const LanguageToggle(compact: true),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, Gap.sm, 20, Gap.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The mark sits on the page unplated: this surface is pure
                    // white, so the JPEG's matte is invisible here.
                    const Center(child: AppLogo(height: 38, plate: false)),
                    Gap.h24,

                    Text(
                      _isSignUp ? s.authSignUpHeadline : s.authSignInHeadline,
                      style: text.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    Gap.h8,
                    Text(
                      _isSignUp
                          ? s.authSignUpHeadlineSub
                          : s.authSignInHeadlineSub,
                      style: text.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    Gap.h24,

                    SegmentedTabs(
                      labels: [s.authTabSignIn, s.authTabSignUp],
                      index: _mode.index,
                      onChanged: (i) => _switchTo(AuthMode.values[i]),
                    ),
                    Gap.h24,

                    // Animated so swapping tabs grows the form rather than
                    // snapping the button to a new position under the thumb.
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _form(s),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(AppStrings s) {
    return Form(
      key: _formKeys[_mode],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isSignUp) ...[
            AuthField(
              controller: _name,
              icon: Icons.person_outline_rounded,
              hint: s.fieldFullName,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.errRequired : null,
            ),
            Gap.h12,
          ],

          AuthField(
            controller: _email,
            icon: Icons.mail_outline_rounded,
            hint: s.fieldEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return s.errRequired;
              if (!Validators.isEmail(v)) return s.errEmail;
              return null;
            },
          ),
          Gap.h12,

          AuthField(
            controller: _phone,
            icon: Icons.phone_iphone_rounded,
            hint: s.fieldPhone,
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
          Gap.h12,

          // The wallet's own account number, not the citizen's NRC — so no
          // township-code mask and no NRC pattern check. It is validated for
          // length and character set only.
          AuthField(
            controller: _uid,
            icon: Icons.badge_outlined,
            hint: s.fieldUidNumber,
            numeric: true,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
              LengthLimitingTextInputFormatter(24),
            ],
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return s.errRequired;
              if (value.length < 6) return s.errUidNumber;
              return null;
            },
          ),

          Gap.h24,
          PrimaryButton(
            label: _isSignUp ? s.authTabSignUp : s.authTabSignIn,
            onPressed: _submit,
          ),
          Gap.h8,
          TextButton(
            onPressed: () =>
                _switchTo(_isSignUp ? AuthMode.signIn : AuthMode.signUp),
            child: Text(
              _isSignUp ? s.authHaveAccount : s.authNoAccount,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
