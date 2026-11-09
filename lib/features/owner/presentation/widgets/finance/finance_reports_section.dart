import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../finance/domain/entities/finance_transfer_entity.dart';
import 'finance_pnl_report.dart';

/// Audit impl (O34): the finance hub's Reports tab — the P&L
/// statement for the period plus a link to the full reports
/// screen. Extracted from [OwnerFinanceView] so the view stays
/// under the 250-line cap.
class FinanceReportsSection extends StatelessWidget {
  final String shopId;
  final List<BookingEntity> bookings;
  final List<FinanceTransferEntity> transfers;

  const FinanceReportsSection({
    super.key,
    required this.shopId,
    required this.bookings,
    required this.transfers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        FinancePnLReport(
          shopName: shopId,
          bookings: bookings,
          transfers: transfers,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: Text(l10n.financeViewReports),
            onPressed: () => context.push(RouteNames.ownerReports),
          ),
        ),
      ],
    );
  }
}
