import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/whatsapp_credits_models.dart';

/// W3 — "Credits added" confirmation (deck p.19 screen 3).
///
/// Two honest states, never a fake one:
/// - Added: shown ONLY when a purchase actually completed — the
///   caller passes the real previous and new balances (balance
///   increased after admin approval). No "enough for N bookings"
///   derivation is shown; that deck line assumes a fixed
///   messages-per-booking ratio that does not exist.
/// - Request submitted: shown right after the owner submits a bank-
///   transfer purchase request — credits are added only after payment
///   verification.
class OwnerWhatsappCreditsAddedView extends StatelessWidget {
  final bool requestSubmitted;
  final int? previousBalance;
  final int? newBalance;
  final int? pack;
  final int? price;

  const OwnerWhatsappCreditsAddedView({
    super.key,
    this.requestSubmitted = false,
    this.previousBalance,
    this.newBalance,
    this.pack,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submitted = requestSubmitted;
    // Named pack for the stored credits count; null keeps the bare
    // number, so an unknown count is never given a wrong name.
    // (Local copy: the public `pack` field does not promote.)
    final credits = pack;
    final packName = credits == null
        ? null
        : whatsappCreditPackForCredits(credits)?.name;
    final packLabel = credits == null
        ? null
        : (packName == null ? '$credits' : '$packName · $credits');
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: submitted
                  ? l10n.creditsRequestSubmittedTitle
                  : l10n.creditsAddedTitle,
              subtitle: l10n.creditsTitle,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  Center(
                    child: Icon(
                      submitted
                          ? Icons.hourglass_top_rounded
                          : Icons.check_circle_rounded,
                      size: 64,
                      // OW-m30: theme tokens, not raw Colors.
                      color: submitted ? AppColors.orangeFill : AppColors.accentSuccessStrong,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    submitted
                        ? l10n.creditsRequestSubmittedTitle
                        : l10n.creditsAddedTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submitted
                        ? l10n.creditsRequestSubmittedBody
                        : l10n.creditsAddedBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (!submitted) ...[
                    if (pack != null)
                      _Row(label: l10n.creditsPack, value: packLabel!),
                    if (price != null)
                      _Row(
                          label: l10n.creditsPrice,
                          value: l10n.amountRs(formatRs(price!))),
                    if (previousBalance != null)
                      _Row(
                          label: l10n.creditsPreviousBalance,
                          value: '$previousBalance'),
                    if (newBalance != null)
                      _Row(
                          label: l10n.creditsNewBalance,
                          value: '$newBalance'),
                  ] else ...[
                    if (pack != null)
                      _Row(label: l10n.creditsPack, value: packLabel!),
                    if (price != null)
                      _Row(
                          label: l10n.creditsPrice,
                          value: l10n.amountRs(formatRs(price!))),
                  ],
                  const SizedBox(height: 16),
                  DebouncedButton(
                    text: l10n.creditsDone,
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ),
        ],
      ),
    );
  }
}
