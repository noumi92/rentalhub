import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/money_format.dart';

/// Phase B (H): the finance hub's month summary card and the
/// links to dues, cash closing and car P&L, extracted from
/// [OwnerFinanceView] so the view stays under the 250-line cap.
class FinanceMonthSummary extends StatelessWidget {
  final int bookingRevenue;
  final int ledgerIncome;
  final int expenses;

  /// Audit impl (O34): the label for the period these numbers
  /// cover — the finance hub's period selector changes it, so it
  /// is passed in instead of always reading "This month".
  final String? periodLabel;

  const FinanceMonthSummary({
    super.key,
    required this.bookingRevenue,
    required this.ledgerIncome,
    required this.expenses,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final net = bookingRevenue + ledgerIncome - expenses;
    return Column(
      children: [
        Container(
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
              Text(periodLabel ?? l10n.financeThisMonth,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              Text(l10n.financeNetAmount(formatRs(net)),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  )),
              const SizedBox(height: 8),
              Text(
                  l10n.financeMonthBreakdown(formatRs(bookingRevenue), formatRs(ledgerIncome), formatRs(expenses)),
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _linkTile(context, Icons.people_rounded,
                  l10n.financeCustomerDues, RouteNames.ownerDues),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _linkTile(context, Icons.account_balance_wallet_rounded,
                  l10n.financeCashClosing, RouteNames.ownerCashClosing),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _linkTile(context, Icons.directions_car_rounded,
                  l10n.financeCarPnl, RouteNames.ownerCarPnL),
            ),
          ],
        ),
      ],
    );
  }

  /// Audit §24: three `OutlinedButton.icon`s in one row overflowed
  /// at 360px (icon + padding + label > ~103dp each). Stacked icon
  /// tiles — icon above a two-line label — fit at 360px and in Urdu.
  Widget _linkTile(
      BuildContext context, IconData icon, String label, String route) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: scheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
