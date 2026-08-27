import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
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
/// switching tabs keeps the email and UID intact.
///
/// Both forms ask for email *and* UID. That is heavier than a conventional
/// login, and deliberately so: this is a government identity wallet, and the
/// pair together is what the issuer matches against the national register.
/// No phone number is asked for here — the one-time code goes to the address
/// on file, so a handset number would be a field with nothing behind it.
///
/// Creating an account does not sign the user in. It confirms and returns to
/// the sign-in tab, because everything past this screen belongs to a session
/// and a session starts by signing in — the same path the user will take on
/// every later visit, learned once here.
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
  final _uid = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restore anything already captured, so Back never loses typing.
    final draft = WalletScope.read(context).draft;
    _name.text = draft.nameEn.isNotEmpty ? draft.nameEn : draft.nameMy;
    _email.text = draft.email;
    _uid.text = draft.uid;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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
      ..uid = _uid.text.trim()
      // The one-time code goes to the address. This is the wallet's own
      // account rather than a handset, and the mailbox is the channel the
      // register can reach wherever the citizen is.
      ..method = RegistrationMethod.email;

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
      _confirmSignUp();
      return;
    }

    // Signing in is a one-time-code challenge rather than a stored-password
    // check: there is no cheaper way to prove the person still holds the
    // address on file, and what follows it — PIN, then the holder key — is
    // the same work either way.
    Navigator.of(context).pushNamed(Routes.registerOtp);
  }

  /// Confirms the new account, then hands the user to the sign-in tab with
  /// what they typed still in place — nothing to re-enter.
  Future<void> _confirmSignUp() async {
    final s = AppStrings.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded,
            size: 44, color: AppColors.success),
        title: Text(s.authSignUpDoneTitle, textAlign: TextAlign.center),
        content: Text(
          s.authSignUpDoneBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.authTabSignIn),
          ),
        ],
      ),
    );

    if (!mounted) return;
    _switchTo(AuthMode.signIn);
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
          // No "no account yet?" link under it: the segmented control above is
          // the same switch, and offering it twice only pushed the action
          // itself further down a short handset.
          PrimaryButton(
            label: _isSignUp ? s.authTabSignUp : s.authTabSignIn,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
