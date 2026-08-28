import 'package:eid_wallet/core/models/wallet_models.dart';
import 'package:eid_wallet/core/models/wallet_state.dart';
import 'package:eid_wallet/features/credential/credential_detail_screen.dart';
import 'package:eid_wallet/features/credential/credential_pending_screen.dart';
import 'package:eid_wallet/features/home/wallet_home_screen.dart';
import 'package:eid_wallet/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('CredentialRequest', () {
    test('counts the estimate in working days, skipping the weekend', () {
      // Filed on a Friday: three working days lands on the Wednesday, not on
      // the Monday a raw +3 days would promise.
      final friday = CredentialRequest(
        reference: 'EID-20260828-0900',
        kind: CredentialKind.nationalId,
        issuerKey: 'moha',
        submittedAt: DateTime(2026, 8, 28, 9),
      );

      expect(DateTime(2026, 8, 28).weekday, DateTime.friday);
      expect(friday.submittedDate, '2026-08-28');
      expect(friday.expectedDate, '2026-09-02');
    });

    test('the reference is derived from the submission time', () {
      expect(
        CredentialRequest.referenceFor(DateTime(2026, 8, 27, 10, 16)),
        'EID-20260827-1016',
      );
    });
  });

  group('WalletState', () {
    test('submitting files one request and no credential', () {
      final wallet = WalletState();

      final first = wallet.submitCredentialRequest();

      expect(wallet.hasPendingRequest, isTrue);
      expect(wallet.credentials, isEmpty,
          reason: 'the issuer has not approved anything yet');
      expect(first.status, CredentialRequestStatus.underReview);

      // A holder who taps twice has one application, not two references for a
      // clerk to reconcile.
      expect(wallet.submitCredentialRequest().reference, first.reference);
    });

    test('approval turns the pending request into a held credential',
        () async {
      final wallet = WalletState()..submitCredentialRequest();

      final credential = await wallet.approvePendingRequest();

      expect(wallet.hasPendingRequest, isFalse);
      expect(credential.kind, CredentialKind.nationalId);
      expect(
        wallet.credentials.where((c) => c.kind == CredentialKind.nationalId),
        hasLength(1),
      );
    });
  });

  group('Request pending screen', () {
    testWidgets('names the wait, its end date and the reference',
        (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      wallet.pendingRequest = CredentialRequest.sample;

      await tester.pumpWidget(wrapScreen(
        const CredentialPendingScreen(justSubmitted: true),
        wallet: wallet,
      ));
      // The hero pulses forever, so the clock is driven rather than settled.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(my.requestPendingTitle), findsOneWidget);
      expect(find.text(my.statusUnderReview), findsOneWidget);

      // The record sits below the fold on a phone, so the rest is asserted
      // where the user would read it — after scrolling down to it.
      await _scrollTo(tester, find.text(CredentialRequest.sample.reference));
      expect(find.text(CredentialRequest.sample.submittedDate), findsOneWidget);
      expect(find.text(CredentialRequest.sample.expectedDate), findsOneWidget);
    });

    testWidgets('opened from Home it is a status view with no actions',
        (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      wallet.pendingRequest = CredentialRequest.sample;

      await tester.pumpWidget(wrapScreen(
        const CredentialPendingScreen(),
        wallet: wallet,
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(my.requestPendingTitle), findsOneWidget);
      expect(find.text(my.goToWalletHome), findsNothing);
      expect(find.text(my.simulateApproval), findsNothing);
      expect(find.byType(PrimaryButton), findsNothing);
      expect(find.byType(SecondaryButton), findsNothing);
    });
  });

  group('Wallet home', () {
    testWidgets('shows an open request, and drops the invitation to apply',
        (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState();
      wallet.pendingRequest = CredentialRequest.sample;

      await tester.pumpWidget(
          wrapScreen(const WalletHomeScreen(), wallet: wallet));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(my.requestInProgress), findsOneWidget);
      expect(find.text(my.statusUnderReview), findsOneWidget);
      expect(find.text(CredentialRequest.sample.expectedDate), findsOneWidget);
      expect(find.text(my.noCredentials), findsNothing,
          reason: 'they have already applied — asking again reads as a failure');
    });

    testWidgets('drops the request card once the credential is held',
        (tester) async {
      // Wider than a phone on purpose. The bundled faces are not registered
      // under the test binding, and the credential deck this wallet now shows
      // overflows by a few pixels on the substitute metrics — a harness
      // artefact that says nothing about the layout on a device.
      tester.view.physicalSize = const Size(1500, 3000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final wallet = WalletState()..submitCredentialRequest();
      await wallet.approvePendingRequest();

      await tester.pumpWidget(wrapScreen(
        const WalletHomeScreen(),
        wallet: wallet,
        locale: const Locale('en'),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(en.requestInProgress), findsNothing);
    });

    // The same tile, three situations. Nothing held and nothing filed is the
    // only one that should open the issuance flow.
    testWidgets('"View credential" opens issuance on an empty wallet',
        (tester) async {
      expect(await _viewCredentialRoute(tester, WalletState()),
          '/credential/request');
    });

    testWidgets('"View credential" opens the waiting screen while a request is '
        'open', (tester) async {
      expect(
        await _viewCredentialRoute(
            tester, WalletState()..submitCredentialRequest()),
        '/credential/pending',
        reason: 'a holder who has applied must not be asked to apply again',
      );
    });

    testWidgets('"View credential" opens the record once the ID is held',
        (tester) async {
      final wallet = WalletState()..submitCredentialRequest();
      await wallet.approvePendingRequest();

      expect(await _viewCredentialRoute(tester, wallet), '/credential/detail');
    });
  });

  group('Credential detail screen', () {
    testWidgets('prints the held record with its values and offers no action',
        (tester) async {
      await setPhoneSurface(tester);
      final wallet = WalletState()..submitCredentialRequest();
      await wallet.approvePendingRequest();

      await tester.pumpWidget(wrapScreen(
        const CredentialDetailScreen(),
        wallet: wallet,
        locale: const Locale('en'),
      ));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(en.yourDigitalIdTitle), findsOneWidget);
      expect(find.text('Aung Ko Ko'), findsOneWidget);
      expect(find.text('12/ABC(N)123456'), findsOneWidget);

      // No "Request Credential" — the credential is already held, and a second
      // application is the one thing this screen must not offer.
      expect(find.text(en.requestCredential), findsNothing);
      expect(find.byType(PrimaryButton), findsNothing);
    });
  });
}

/// Taps Wallet Home's "View credential" action and reports the route it pushed.
///
/// The surface is set wider than a phone on purpose: the bundled faces are not
/// registered under the test binding, and the credential deck overflows by a
/// few pixels on the substitute metrics — a harness artefact that says nothing
/// about the layout on a device, and nothing about the routing under test.
Future<String?> _viewCredentialRoute(
    WidgetTester tester, WalletState wallet) async {
  tester.view.physicalSize = const Size(1500, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  String? pushed;
  await tester.pumpWidget(wrapScreen(
    const WalletHomeScreen(),
    wallet: wallet,
    locale: const Locale('en'),
    onGenerateRoute: (settings) {
      pushed ??= settings.name;
      return MaterialPageRoute<dynamic>(builder: (_) => const SizedBox());
    },
  ));
  await tester.pump(const Duration(milliseconds: 600));

  await tester.tap(find.text(en.actionAdd));
  // Home keeps a looping animation alive, so the clock is driven rather than
  // settled.
  await tester.pump(const Duration(milliseconds: 400));
  return pushed;
}

/// Scrolls the screen until [target] is on it. The pending screen is a list
/// taller than a phone, and a lazily-built row below the fold is not in the
/// tree at all — `findsNothing` there would be a finding about the viewport,
/// not about the screen.
Future<void> _scrollTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(target, 240,
        scrollable: find.byType(Scrollable).first);
