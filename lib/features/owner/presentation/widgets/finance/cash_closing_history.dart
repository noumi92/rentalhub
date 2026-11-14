import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../finance/domain/entities/cash_closing_entity.dart';
import 'cash_closing_cards.dart';

/// Audit §26 (extracted from [OwnerCashClosingView] so the view
/// stays under the 250-line cap): the past-closings section.
class CashClosingHistory extends StatelessWidget {
  final List<CashClosingEntity> closings;

  const CashClosingHistory({super.key, required this.closings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.financeClosingPast,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (closings.isEmpty)
          Text(l10n.financeClosingEmpty,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ...closings.take(10).map((c) => CashClosingRow(closing: c)),
      ],
    );
  }
}
