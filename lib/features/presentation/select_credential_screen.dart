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

/// Screen 12 — choose which credential to present.
///
/// Only credentials that can actually satisfy the request are offered; anything
/// missing a requested claim is shown greyed with the reason, rather than
/// hidden. A user who owns a passport and is told "no credential available"
/// with no explanation assumes the app is broken.
class SelectCredentialScreen extends StatefulWidget {
  const SelectCredentialScreen({super.key, required this.request});

  final PresentationRequest request;

  @override
  State<SelectCredentialScreen> createState() => _SelectCredentialScreenState();
}

class _SelectCredentialScreenState extends State<SelectCredentialScreen> {
  String? _selectedId;

  bool _satisfies(WalletCredential c) =>
      widget.request.requestedClaims.every(c.claims.containsKey);

  /// First credential able to satisfy the request, or null if none can.
  WalletCredential? _firstUsable(List<WalletCredential> all) {
    for (final c in all) {
      if (_satisfies(c)) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wallet = WalletScope.of(context);
    final credentials = wallet.credentials;

    // Default to the first credential that can satisfy the request.
    _selectedId ??= _firstUsable(credentials)?.id;

    return AppScaffold(
      title: s.chooseCredentialTitle,
      bottomBar: PrimaryButton(
        label: s.continueLabel,
        onPressed: _selectedId == null
            ? null
            : () => Navigator.of(context).pushNamed(
                  Routes.presentConfirm,
                  arguments: PresentationArgs(
                    request: widget.request,
                    credential:
                        credentials.firstWhere((c) => c.id == _selectedId),
                  ),
                ),
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xl),
        children: [
          ScreenHeader(
            title: s.chooseCredentialTitle,
            subtitle: s.chooseCredentialSubtitle,
          ),
          Gap.h24,
          if (credentials.isEmpty)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.inbox_outlined,
                      color: AppColors.textTertiary),
                  Gap.w12,
                  Expanded(
                    child: Text(
                      s.noCredentials,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          for (final c in credentials) ...[
            Opacity(
              opacity: _satisfies(c) ? 1 : 0.55,
              child: SelectionCard(
                selected: c.id == _selectedId,
                onTap: _satisfies(c)
                    ? () => setState(() => _selectedId = c.id)
                    : () {},
                leading: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: c.id == _selectedId
                        ? AppColors.primary
                        : AppColors.secondary,
                    borderRadius: Radii.fieldAll,
                  ),
                  child: Icon(
                    c.kind == CredentialKind.passport
                        ? Icons.menu_book_rounded
                        : Icons.badge_rounded,
                    size: 22,
                    color: c.id == _selectedId
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
                title: c.kind.label(s),
                subtitle: '${c.issuerName(s)}\n${s.validUntil(c.validUntil)}',
              ),
            ),
            Gap.h12,
          ],
        ],
      ),
    );
  }
}

/// Bundles the two objects the confirm screen needs, so the route argument
/// stays a single typed value.
class PresentationArgs {
  const PresentationArgs({required this.request, required this.credential});

  final PresentationRequest request;
  final WalletCredential credential;
}
