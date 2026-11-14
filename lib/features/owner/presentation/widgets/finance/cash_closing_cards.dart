import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../finance/domain/entities/cash_closing_entity.dart';
import '../../../../../core/theme/card_decoration.dart';

/// Phase B (H5): the cash-closing summary card and one past
/// closing row, extracted from [OwnerCashClosingView] so the view
/// stays under the 250-line cap.
class CashClosingSummaryCard extends StatelessWidget {
  final int expectedCash;
  final int openingCash;

  /// Null until the owner types a counted amount — the card must
  /// never show a false difference on first paint (audit §26).
  final int? difference;
  final int cashInToday;
  final int cashOutToday;

  /// The typed counted amount (for the exact-match line).
  final int? countedCash;

  const CashClosingSummaryCard({
    super.key,
    required this.expectedCash,
    required this.openingCash,
    required this.difference,
    this.cashInToday = 0,
    this.cashOutToday = 0,
    this.countedCash,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = difference;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Audit §24: the light navy token in dark mode was barely
        // distinguishable from the dark surface.
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.financeClosingExpected,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          Text(l10n.amountRs(formatRs(expectedCash)),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 4),
          // Audit §26: the expected figure was opaque — the
          // arithmetic behind it (opening + cash in − cash out).
          Text(
              '${l10n.amountRs(formatRs(openingCash))} + ${l10n.amountRs(formatRs(cashInToday))} − ${l10n.amountRs(formatRs(cashOutToday))}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          _differenceLine(context, diff, countedCash),
        ],
      ),
    );
  }

  /// Audit §26: a bare signed int said nothing about over/short.
  /// The card is navy in both modes, so the over/short text uses
  /// the dark-mode danger/success text tokens for contrast.
  Widget _differenceLine(BuildContext context, int? diff, int? counted) {
    final l10n = AppLocalizations.of(context)!;
    const dark = Brightness.dark;
    if (diff == null) {
      return Text(l10n.financeClosingEnterCounted,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white70));
    }
    if (diff == 0) {
      return Text(l10n.financeClosingCounted(formatRs(counted ?? 0), formatRs(0)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70));
    }
    if (diff < 0) {
      return Text(l10n.cashClosingShortBy(formatRs(-diff)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.dangerTextFor(dark),
              ));
    }
    return Text(l10n.cashClosingOverBy(formatRs(diff)),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.successTextFor(dark),
            ));
  }
}

class CashClosingRow extends StatelessWidget {
  final CashClosingEntity closing;

  const CashClosingRow({super.key, required this.closing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${closing.date.day}/${closing.date.month}/${closing.date.year}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
              l10n.financeClosingCounted(formatRs(closing.countedCash), formatRs(closing.difference)),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: closing.difference == 0
                      ? AppColors.successTextFor(Theme.of(context).brightness)
                      : AppColors.dangerTextFor(Theme.of(context).brightness),
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
