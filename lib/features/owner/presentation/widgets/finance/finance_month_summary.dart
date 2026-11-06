import 'package:flutter/material.dart';
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
    final net = bookingRevenue + ledgerIncome - expenses;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.royalNavy,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This month',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Net Rs. $net',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                  'Bookings Rs. $bookingRevenue • Other income Rs. $ledgerIncome • Expenses Rs. $expenses',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _linkButton(context, Icons.people_rounded,
                  'Customer dues', RouteNames.ownerDues),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _linkButton(context, Icons.account_balance_wallet_rounded,
                  'Cash closing', RouteNames.ownerCashClosing),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _linkButton(context, Icons.directions_car_rounded,
                  'Car P&L', RouteNames.ownerCarPnL),
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
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => context.push(route),
    );
  }
}
