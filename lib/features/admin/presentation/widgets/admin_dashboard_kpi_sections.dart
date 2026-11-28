import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_kpi_card.dart';
import 'admin_status_chip.dart';

/// Read-only, mobile-first KPI metric sections for [AdminDashboardView].
/// Cards are pure editorial stats (never button-styled) grouped logically:
/// 1. Shops & Fleet
/// 2. Customers (Online vs. Walk-in KPI)
/// 3. Booking Summary (numbers only — no booking detail links)
class AdminDashboardKpiSections extends StatelessWidget {
  const AdminDashboardKpiSections({
    super.key,
    required this.stats,
    required this.canReviewKyc,
  });

  final PlatformStats stats;
  final bool canReviewKyc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final success = adminStatusColor(context, AdminStatusTone.success);
    final warning = adminStatusColor(context, AdminStatusTone.warning);
    final info = adminStatusColor(context, AdminStatusTone.info);
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;
    final totalBookings = stats.onlineBookingCount + stats.walkInBookingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          l10n?.adminKpiSectionShopsFleet ?? 'Shops & Fleet',
        ),
        _kpiGrid(context, [
          AdminKpiCard(
            title: l10n?.admin2_dashboardKpiShops ?? 'Registered shops',
            value: '${stats.shopCount}',
            changeLabel:
                '${stats.verifiedShopCount} ${l10n?.adminKpiVerified ?? 'Verified'} • ${stats.pendingShopCount} ${l10n?.adminKpiPending ?? 'Pending'}',
            icon: Icons.store_rounded,
          ),
          AdminKpiCard(
            title: l10n?.adminKpiFleetVehicles ?? 'Fleet Vehicles',
            value: '${stats.totalVehicleCount}',
            changeLabel:
                '${stats.pendingCarReviewCount} ${l10n?.adminKpiPending ?? 'Pending'}',
            icon: Icons.directions_car_rounded,
            accentColor: info,
          ),
          AdminKpiCard(
            title: l10n?.adminKpiPaidPlans ?? 'Paid Plans',
            value: '${stats.paidShopCount}',
            changeLabel: l10n?.adminTabShopPlans ?? 'Shop Plans',
            icon: Icons.card_membership_rounded,
            accentColor: success,
          ),
        ]),
        const SizedBox(height: 18),
        _sectionHeader(
          context,
          l10n?.adminKpiSectionCustomers ?? 'Customers (Online vs. Walk-in)',
        ),
        _kpiGrid(context, [
          AdminKpiCard(
            title: l10n?.adminKpiOnlineCustomers ?? 'Online Customers',
            value: '${stats.onlineCustomerCount}',
            changeLabel:
                '${stats.verifiedKycCount} ${l10n?.adminKpiVerified ?? 'Verified'} KYC',
            icon: Icons.people_rounded,
            accentColor: success,
          ),
          AdminKpiCard(
            title: l10n?.adminTabKycQueue ?? 'KYC Queue',
            value: '${stats.pendingKycCount}',
            changeLabel: l10n?.adminKpiPending ?? 'Pending',
            icon: Icons.badge_rounded,
            accentColor: stats.pendingKycCount > 0 ? warning : info,
          ),
          AdminKpiCard(
            title: l10n?.adminKpiWalkInCustomers ?? 'Walk-in Customers',
            value: '${stats.walkInCustomerCount}',
            changeLabel:
                l10n?.adminKpiShopManagedOnly ?? 'Shop-managed (KPI only)',
            icon: Icons.storefront_rounded,
            accentColor: neutral,
          ),
          AdminKpiCard(
            title: l10n?.adminKpiBlacklisted ?? 'Blacklisted',
            value: '${stats.blacklistedCount}',
            changeLabel: l10n?.admin2_navBlacklist ?? 'Blacklist',
            icon: Icons.gpp_bad_rounded,
            accentColor: warning,
          ),
        ]),
        const SizedBox(height: 18),
        _sectionHeader(
          context,
          l10n?.adminBookingStatsTitle ?? 'Booking Metrics (Summary Only)',
        ),
        _kpiGrid(context, [
          AdminKpiCard(
            title: l10n?.admin2_navBookings ?? 'Total Bookings',
            value: '$totalBookings',
            changeLabel:
                '${stats.onlineBookingCount} Online • ${stats.walkInBookingCount} Walk-in',
            icon: Icons.analytics_outlined,
            accentColor: info,
          ),
          AdminKpiCard(
            title: l10n?.admin2_dashboardKpiBookings ?? 'Active bookings',
            value: '${stats.activeBookingCount}',
            changeLabel: l10n?.adminKpiOnlineBookings ?? 'Online & Walk-in',
            icon: Icons.calendar_month_rounded,
            accentColor: success,
          ),
          AdminKpiCard(
            title: l10n?.admin2_dashboardKpiDisputes ?? 'Open disputes',
            value: '${stats.openDisputeCount}',
            changeLabel: l10n?.admin2_dashboardKpiDisputesNote ??
                'Awaiting a decision',
            icon: Icons.report_problem_outlined,
            accentColor: stats.openDisputeCount > 0 ? warning : neutral,
          ),
          AdminKpiCard(
            title: l10n?.admin2_dashboardKpiTickets ?? 'Open support tickets',
            value: '${stats.openTicketCount}',
            changeLabel:
                l10n?.admin2_dashboardKpiTicketsNote ?? 'Awaiting a reply',
            icon: Icons.support_agent_rounded,
            accentColor: info,
          ),
        ]),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w < 340
            ? 1
            : w < 720
                ? 2
                : cards.length >= 4
                    ? 4
                    : cards.length;
        const gap = 12.0;
        final itemWidth = (w - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }
}
