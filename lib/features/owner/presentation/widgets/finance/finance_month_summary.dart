import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/route_names.dart';

/// Phase B (H): the finance hub's month summary card and the
/// links to dues, cash closing and car P&L, extracted from
/// [OwnerFinanceView] so the view stays under the 250-line cap.
class FinanceMonthSummary extends StatelessWidget {
  final int bookingRevenue;
  final int ledgerIncome;
  final int expenses;

  const FinanceMonthSummary({
    super.key,
    required this.bookingRevenue,
    required this.ledgerIncome,
    required this.expenses,
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.financeThisMonth,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
              Text(l10n.financeNetAmount(net),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  )),
              const SizedBox(height: 8),
              Text(
                  l10n.financeMonthBreakdown(bookingRevenue, ledgerIncome, expenses),
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _linkButton(context, Icons.people_rounded,
                  l10n.financeCustomerDues, RouteNames.ownerDues),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _linkButton(context, Icons.account_balance_wallet_rounded,
                  l10n.financeCashClosing, RouteNames.ownerCashClosing),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _linkButton(context, Icons.directions_car_rounded,
                  l10n.financeCarPnl, RouteNames.ownerCarPnL),
            ),
          ],
        ),
      ],
    );
  }

  Widget _linkButton(
      BuildContext context, IconData icon, String label, String route) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
      onPressed: () => context.push(route),
    );
  }
}
