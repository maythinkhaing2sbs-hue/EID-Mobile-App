# National EID Mobile ID Wallet

Flutter implementation of the national digital-ID wallet: OpenID4VCI issuance,
OpenID4VP presentation, and the bank-side verification result. Myanmar is the
default language, with a global toggle to English on every screen.

```
flutter pub get
flutter run                 # phone
flutter run -d chrome       # desktop browser — renders inside a phone mockup
```

No third-party packages. Fonts are bundled, so the app renders correctly on
first launch, offline, on a device that has never seen a Myanmar font.

### Phone mockup on desktop

This is a fixed portrait product. Stretched across a 1900px browser window a
56-high pill button becomes a 1900-wide pill and the design stops being
reviewable, so on viewports **620px wide or wider** the app renders inside a
phone frame — `lib/widgets/device_frame.dart`.

The frame does more than crop: it overrides `MediaQuery` so everything inside
measures itself against a 390×844 screen with realistic notch and home-indicator
insets, and it wraps the `Navigator`, so dialogs and bottom sheets stay inside
the phone. The simulated status bar switches to white on dark screens (the QR
scanner), driven by a `NavigatorObserver` rather than by anything the screens
know about — see `_darkScreens` in `app.dart`.

Below 620px it is a pure pass-through; a shipped mobile build never sees it.
Disable it entirely with `--dart-define=DEVICE_FRAME=off`.

---

## Design system

Everything visual resolves to four files under `lib/core/theme/`. No screen
declares a raw colour, font size or spacing value.

### Colour — `app_colors.dart`

| Role | Token | Value |
|---|---|---|
| Primary | `AppColors.primary` | `#266DD3` Deep Trust Blue |
| Primary (pressed / gradient end) | `primaryDark` | `#1B4F9C` |
| Secondary surface | `secondary` | `#E3F2FD` Calming Sky Blue |
| Success | `success` | `#4CAF50` |
| Alert | `warning` | `#FFC107` |
| Refuse / error | `danger` | `#D32F2F` |
| Page background | `surfaceMuted` | `#F5F5F5` |
| Card background | `surface` | `#FFFFFF` |

Supporting neutrals (`textPrimary` `#16202E`, `textSecondary` `#5B6577`,
`border` `#E2E6EE`) are derived to hold WCAG AA contrast on both approved
backgrounds. Two shadow presets — `cardShadow` for every card, `raisedShadow`
for the credential card, which is the only saturated surface in the product.

### Typography — `app_typography.dart`

Locale-aware. `AppTypography.forLocale(locale)` returns the whole text theme.

- **Myanmar (`my`, default)** — Noto Serif Myanmar, with line height scaled
  ×1.18 so stacked diacritics do not clip between lines.
- **English (`en`)** — Roboto Slab.
- **Numerals, always** — `AppTypography.numeric()` forces Roboto Slab with
  tabular figures for OTP boxes, PIN entry, dates, UID and document numbers, so
  digits align in a column regardless of language.
- Every style declares the other family in `fontFamilyFallback`, so a Myanmar
  name on an English screen never degrades to tofu boxes.

### Spacing and shape — `app_dimens.dart`

4pt grid (`Gap.xs`…`Gap.xxxl`) with pre-built `SizedBox` constants. Radii:
`16` cards, `12` fields, pill for buttons. Page gutter is `20`, a little wider
than Material's default because Myanmar text is visually dense.

### Component theme — `app_theme.dart`

Primary action: full-width pill, 56 high, thumb-reachable, identical position
on every screen. Fields are outlined with inline validation. Text scaling is
clamped to 1.3× in `app.dart` — beyond that the credential card and OTP boxes
break, and clipping is worse for a low-vision user than a smaller cap.

---

## Screens

| # | Screen | File |
|---|---|---|
| 1 | Welcome | `features/onboarding/welcome_screen.dart` |
| 2 | Registration method | `features/registration/registration_method_screen.dart` |
| 3 | EID registration form | `features/registration/eid_registration_screen.dart` |
| 4 | Verify OTP | `features/registration/otp_screen.dart` |
| 5 | Create PIN → confirm | `features/security/pin_setup_screen.dart` |
| 5b | Enable biometrics | `features/security/biometrics_screen.dart` |
| 6 | Wallet ready | `features/registration/wallet_ready_screen.dart` |
| 7 | Create holder key pair | `features/keys/create_key_pair_screen.dart` |
| 8 | Key pair created | `features/keys/key_pair_created_screen.dart` |
| 9 | Request credential | `features/credential/request_credential_screen.dart` |
| 9b | Issuing → credential issued | `features/credential/credential_issuing_screen.dart` |
| 10 | QR scan | `features/presentation/qr_scan_screen.dart` |
| 11 | Review request | `features/presentation/review_request_screen.dart` |
| 12 | Select credential | `features/presentation/select_credential_screen.dart` |
| 13 | Confirm & share | `features/presentation/confirm_share_screen.dart` |
| 14 | Bank — reading data | `features/verifier/reading_data_screen.dart` |
| 15 | Bank — verification result | `features/verifier/verification_result_screen.dart` |
| — | Wallet home | `features/home/wallet_home_screen.dart` |
| — | Unlock (existing wallet) | `features/security/unlock_screen.dart` |

Two screens beyond the original fifteen exist because the flow is not walkable
without them: **wallet home**, which every flow starts or ends at, and
**unlock**, the destination of "Sign In with Existing Wallet". Screens 5b and 9b
are the second halves of designed screens 5 and 9 respectively.

### Notable interaction decisions

- **Language toggle first.** On Welcome it sits top-right, outside any card,
  above the fold — a citizen who opens the app in the wrong language has to be
  able to fix that before reading anything else. Elsewhere it is a compact
  app-bar control.
- **PIN set and confirm share one screen.** Pushing a second route would let
  Back strand the user in a half-set PIN.
- **Consent is a checkbox, not a button.** On Confirm & Share the actual claim
  *values* are shown, and Share stays disabled until the box is ticked — a
  button labelled "Share" is not by itself a record of informed consent.
- **Decline is always reachable.** Red text button, full height, next to
  Continue — never buried or styled as an afterthought.
- **Biometrics is offered, never pressured.** "Not now" is equally reachable
  and the PIN keeps working.
- **Issuance shows named steps, not a spinner.** Authorize → consent → bind key
  → sign → store. A user told what is happening waits; a user watching an
  anonymous spinner force-quits.
- **The verifier's screens drop wallet branding.** No back button, no language
  toggle, verifier name in the title — the handoff to another party's app
  should feel like one.

---

## Architecture

```
lib/
  main.dart              orientation lock, system chrome
  app.dart               MaterialApp, scopes, text-scale clamp
  core/
    theme/               colours, typography, dimensions, component theme
    l10n/                string tables + locale controller
    models/              credential/claim/key models, in-memory wallet state
    router/routes.dart   named routes with typed arguments
  widgets/               the shared component library
  features/<flow>/       one file per screen
```

State is two `ChangeNotifier`s hoisted above `MaterialApp`: `LocaleController`
(language) and `WalletState` (draft, PIN, holder key, credentials). A language
change re-themes and re-translates every route already on the stack.

Navigation is named routes with a hand-written `onGenerateRoute`. Arguments are
read through `Routes._arg<T>`, which returns `null` rather than throwing when a
route is reached without its argument — a deep link or a restored stack falls
back to home instead of crashing.

### Localisation

`AppStrings` holds two `const` maps reached through typed getters, so a mistyped
key is a compile error at the call site. The delegate returns a
`SynchronousFuture`; an async load makes `Localizations` render one empty frame
on every language switch, which shows up as a white flash.

Adding a string means adding one getter and one entry per locale. `flutter test`
fails if the two tables' key sets diverge, if a getter resolves to a bare key,
or if a non-templated string contains a `{` placeholder.

---

## What is mocked

Every stub is a method body, not a screen. Swapping in the real implementation
does not change any UI file.

| Concern | Where | Replace with |
|---|---|---|
| Key generation | `WalletState.createHolderKey` | Android Keystore / iOS Secure Enclave — generate ES256 in hardware, return only the public key |
| Credential issuance | `WalletState.issueCredential` | OpenID4VCI authorization-code flow: authorize → token → credential request carrying the holder public key as PoP |
| Presentation | `ConfirmShareScreen._share` | Sign `vp_token` with the holder key, POST to `response_uri` |
| Verification | `ReadingDataScreen` / `VerificationResultScreen` | Real signature, issuer-cert, integrity, device-auth and status-list checks |
| QR camera | `ScannerFrame.preview` + `QrScanScreen._onDetected` | A scanner plugin's preview widget; forward the decoded request URI to `_onDetected` |
| PIN storage | `WalletState.setPin` | Hash + hardware-backed secure storage. **The PIN is currently held in memory in plain text** |
| Biometrics | `BiometricsScreen._finish` | `local_auth`; the screen only records the user's choice today |

The QR screen carries a **"Simulate a successful scan"** button so the
presentation flow is walkable before a camera plugin is wired up. Remove it with
the placeholder preview.

OTP accepts any six digits except `000000`, which is wired to the failure path
so the error state is reachable during review.

---

## Tests

```
flutter test          # 29 tests
flutter analyze       # clean
```

Covers UID/email/phone/name validators, form validation and input formatting,
locale-table integrity, the language toggle, consent gating on Confirm & Share,
credential eligibility on Select Credential, `PinController`, and `WalletState`.

### Screen previews

```
flutter test tool/screenshots_test.dart --update-goldens
```

Renders all 18 screens in both languages to `tool/goldens/{my,en}/`. These are
review artefacts, not golden assertions — text rasterisation differs per
platform, so running without `--update-goldens` is expected to fail.
