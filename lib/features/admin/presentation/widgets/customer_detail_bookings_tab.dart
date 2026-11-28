import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'admin_kpi_card.dart';
import 'admin_status_chip.dart';

/// Read-only historical booking KPIs (numbers only — no individual
/// booking rows) for an Online Customer inside Admin Customer Detail.
class CustomerDetailBookingsTab extends StatelessWidget {
  const CustomerDetailBookingsTab({
    super.key,
    required this.detail,
    this.padding = const EdgeInsets.all(16),
  });

  final CustomerDetail detail;
  final EdgeInsetsGeometry padding;

  int _count(Set<String> statuses) =>
      detail.bookings.where((b) => statuses.contains(b.status)).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEn();
    final total = detail.bookings.length;
    final pendingCount = _count({'requested', 'approved', 'payment_submitted'});
    final activeCount = _count({'paid', 'active'});
    final completedCount = _count({'completed'});
    final cancelledCount = _count({'cancelled', 'rejected'});
    final disputedCount = _count({'disputed'});
    final success = adminStatusColor(context, AdminStatusTone.success);
    final warning = adminStatusColor(context, AdminStatusTone.warning);
    final info = adminStatusColor(context, AdminStatusTone.info);
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;

    final cards = [
      AdminKpiCard(
        title: l10n.admin2_navBookings,
        value: '$total',
        changeLabel: l10n.admin2_customerDetailBookingHistory,
        icon: Icons.analytics_outlined,
        accentColor: info,
      ),
      AdminKpiCard(
        title: l10n.bookingsFilterPending,
        value: '$pendingCount',
        changeLabel: l10n.adminKpiPending,
        icon: Icons.schedule_rounded,
        accentColor: warning,
      ),
      AdminKpiCard(
        title: l10n.active,
        value: '$activeCount',
        changeLabel: '${l10n.statusPaid} & ${l10n.active}',
        icon: Icons.directions_car_rounded,
        accentColor: success,
      ),
      AdminKpiCard(
        title: l10n.statusCompleted,
        value: '$completedCount',
        changeLabel: l10n.statusCompleted,
        icon: Icons.check_circle_outline_rounded,
        accentColor: success,
      ),
      AdminKpiCard(
        title: l10n.statusCancelled,
        value: '$cancelledCount',
        changeLabel: '${l10n.statusCancelled} / ${l10n.statusRejected}',
        icon: Icons.cancel_outlined,
        accentColor: neutral,
      ),
      AdminKpiCard(
        title: l10n.statusDisputed,
        value: '$disputedCount',
        changeLabel: l10n.admin2_navDisputes,
        icon: Icons.gavel_rounded,
        accentColor: disputedCount > 0 ? warning : neutral,
      ),
    ];

    return SingleChildScrollView(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth < 340
              ? 1
              : constraints.maxWidth < 720
                  ? 2
                  : 3;
          const gap = 12.0;
          final w = (constraints.maxWidth - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: cards.map((c) => SizedBox(width: w, child: c)).toList(),
          );
        },
      ),
    );
  }
}
