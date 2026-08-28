import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/wallet_models.dart';
import '../../core/models/wallet_state.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/icon_motion.dart';
import '../../widgets/pulse_icon.dart';

/// Screen 8c — the request is filed and the issuer has it.
///
/// A national ID is approved by a person checking an application against the
/// civil register, which takes days, not seconds. The screen that ends the
/// issuance flow therefore cannot be a credential: it has to be the *receipt*
/// for a request that is still open.
///
/// One card carries the whole record — the status it is in, what was asked for
/// and of whom, the reference number a support desk would ask for, and the two
/// dates that bound the wait. The date it is expected by is the line that does
/// the work: a wait with an end on it is a wait, and a wait without one is a
/// failure nobody has told the holder about.
///
/// It is reachable again from Wallet Home for as long as the request is open: a
/// wait measured in days is one the user will come back to, and a status they
/// can only see once is a status they do not have.
class CredentialPendingScreen extends StatelessWidget {
  const CredentialPendingScreen({super.key, this.justSubmitted = false});

  /// True when the screen closes the issuance flow, false when it is opened
  /// from Home to check on a request already in flight.
  ///
  /// Only the chrome changes: arriving here from the flow there is nothing
  /// useful behind, so the back arrow is dropped rather than offering a way
  /// back into a form that has already been submitted.
  final bool justSubmitted;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    // Falls back to the sample so the screen renders standalone — a preview
    // frame, or a deep link that arrives before any request was filed.
    final request = wallet.pendingRequest ?? CredentialRequest.sample;

    return AppScaffold(
      showBack: !justSubmitted,
      title: justSubmitted ? null : s.credential,
      // Actions only where the screen has to end a flow. Opened from Home to
      // check on a request, it is a status view: the back arrow already goes
      // where "Go to Wallet Home" would, and there is nothing here for the
      // holder to do but read.
      bottomBar: justSubmitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: s.goToWalletHome,
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(Routes.home, (route) => false),
                ),
                // Prototype-only, exactly like the scanner's "simulate a scan":
                // the real trigger is the notification that wakes the wallet
                // days later, and without a stand-in for it the issued screen
                // is unreachable.
                Gap.h8,
                SecondaryButton(
                  label: s.simulateApproval,
                  icon: Icons.verified_rounded,
                  onPressed: () => _approve(context),
                ),
              ],
            )
          : null,
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.xl),
        children: [
          const Center(
            child: PulseIcon(
              icon: Icons.hourglass_top_rounded,
              // Amber, not the brand blue and not green: nothing has succeeded
              // yet. The same tone the status chip below carries, so the mark
              // and the chip are visibly about one thing.
              color: AppColors.warning,
              fill: AppColors.warningSurface,
              iconColor: _amberInk,
              motion: IconMotion.breathe,
            ),
          ),
          Gap.h32,
          ScreenHeader(
            title: s.requestPendingTitle,
            subtitle: s.requestPendingSubtitle,
            align: CrossAxisAlignment.center,
          ),
          Gap.h32,

          AppCard(
            child: Column(
              children: [
                // The status leads the record: it is the reason the holder
                // opened the screen, and every row under it is detail about a
                // request whose state they have to read first.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.statusLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      StatusBadge(
                        label: s.statusUnderReview,
                        tone: BadgeTone.warning,
                        icon: Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.credential,
                  value: request.kind.label(s),
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.issuer,
                  value: request.issuerName(s),
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.requestReference,
                  value: request.reference,
                  numericValue: true,
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.requestSubmittedOn,
                  value: request.submittedDate,
                  numericValue: true,
                ),
                const Divider(height: Gap.lg),
                KeyValueRow(
                  label: s.requestExpectedBy,
                  value: request.expectedDate,
                  numericValue: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final navigator = Navigator.of(context);
    final credential = await WalletScope.read(context).approvePendingRequest();
    // Home is rebuilt underneath first: the issued screen ends a flow the user
    // should not be able to walk backwards into, and leaving it has to land on
    // the wallet that now holds the credential.
    navigator
      ..pushNamedAndRemoveUntil(Routes.home, (route) => false)
      ..pushNamed(Routes.credentialIssued, arguments: credential);
  }
}

/// Readable ink on an amber ground — the same value [StatusBadge] uses for its
/// warning tone, so the card and the chip sitting on it agree.
const Color _amberInk = Color(0xFF8A6100);
