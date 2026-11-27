import 'package:flutter/material.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'admin_detail_section.dart';
import 'admin_status_chip.dart';

/// Phase 2 (2.5) — the customer detail's Bookings tab: the booking
/// history and the guarantors named on those bookings.
class CustomerDetailBookingsTab extends StatelessWidget {
  const CustomerDetailBookingsTab({super.key, required this.detail, this.padding = const EdgeInsets.all(16)});

  final CustomerDetail detail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminDetailSection(
              title: l10n.admin2_customerDetailBookingHistory,
              lines: detail.bookings.isEmpty
                  ? [l10n.admin2_customerDetailNoBookings]
                  : detail.bookings
                      .take(10)
                      .map((b) =>
                          '${b.vehicleName ?? b.vehicleId} • ${humanizeStatus(b.status, l10n)} • ${l10n.amountRs(formatRs(b.totalAmount))}')
                      .toList()),
          AdminDetailSection(
              title: l10n.admin2_customerDetailGuarantors,
              lines: detail.bookings
                  .where((b) => (b.guarantorName ?? '').isNotEmpty)
                  .map((b) =>
                      '${b.guarantorName} • CNIC ${b.guarantorCnic ?? '—'} • ${b.guarantorPhone ?? ''}')
                  .toSet()
                  .toList()),
        ],
      ),
    );
  }
}
