import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_kpi_card.dart';
import 'admin_status_chip.dart';

/// Executive KPI rows for [AdminDashboardView]:
/// 1. Shops & Fleet
/// 2. Customers (Online vs. Walk-in — walk-in is KPI-only, shop-managed)
/// 3. Bookings & Support (walk-in bookings KPI-only)
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
    final pendingPackages =
        stats.pendingSubscriptionCount + stats.pendingCreditRequestCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          l10n?.adminKpiSectionShopsFleet ?? 'Shops & Fleet',
        ),
        _kpiGrid(context, [
          _tappable(
            onTap: () => context.go(RouteNames.adminShops),
            child: AdminKpiCard(
              title: l10n?.admin2_dashboardKpiShops ?? 'Registered shops',
              value: '${stats.shopCount}',
              changeLabel:
                  '${stats.verifiedShopCount} ${l10n?.adminKpiVerified ?? 'Verified'} • ${stats.pendingShopCount} ${l10n?.adminKpiPending ?? 'Pending'}',
              icon: Icons.store_rounded,
            ),
          ),
          _tappable(
            onTap: () => context.go(RouteNames.adminCars),
            child: AdminKpiCard(
              title: l10n?.adminKpiFleetVehicles ?? 'Fleet Vehicles',
              value: '${stats.totalVehicleCount}',
              changeLabel:
                  '${stats.pendingCarReviewCount} ${l10n?.adminKpiPending ?? 'Pending'}',
              icon: Icons.directions_car_rounded,
              accentColor: info,
            ),
          ),
          _tappable(
            onTap: () =>
                context.go('${RouteNames.adminSubscriptions}?tab=plans'),
            child: AdminKpiCard(
              title: l10n?.adminKpiPaidPlans ?? 'Paid Plans',
              value: '${stats.paidShopCount}',
              changeLabel: l10n?.adminTabShopPlans ?? 'Shop Plans',
              icon: Icons.card_membership_rounded,
              accentColor: success,
            ),
          ),
          _tappable(
            onTap: () =>
                context.go('${RouteNames.adminSubscriptions}?tab=requests'),
            child: AdminKpiCard(
              title: l10n?.adminKpiPendingPackageRequests ?? 'Package Requests',
              value: '$pendingPackages',
              changeLabel:
                  '${stats.pendingSubscriptionCount} Plans • ${stats.pendingCreditRequestCount} WhatsApp',
              icon: Icons.upgrade_rounded,
              accentColor: pendingPackages > 0 ? warning : info,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _sectionHeader(
          context,
          l10n?.adminKpiSectionCustomers ?? 'Customers (Online vs. Walk-in)',
        ),
        _kpiGrid(context, [
          _tappable(
            onTap: () => context.go(RouteNames.adminCustomers),
            child: AdminKpiCard(
              title: l10n?.adminKpiOnlineCustomers ?? 'Online Customers',
              value: '${stats.onlineCustomerCount}',
              changeLabel:
                  '${stats.verifiedKycCount} ${l10n?.adminKpiVerified ?? 'Verified'} KYC',
              icon: Icons.people_rounded,
              accentColor: success,
            ),
          ),
          _tappable(
            onTap: canReviewKyc
                ? () => context.go(RouteNames.adminKycReview)
                : null,
            child: AdminKpiCard(
              title: l10n?.adminTabKycQueue ?? 'KYC Queue',
              value: '${stats.pendingKycCount}',
              changeLabel: l10n?.adminKpiPending ?? 'Pending',
              icon: Icons.badge_rounded,
              accentColor: stats.pendingKycCount > 0 ? warning : info,
            ),
          ),
          AdminKpiCard(
            title: l10n?.adminKpiWalkInCustomers ?? 'Walk-in Customers',
            value: '${stats.walkInCustomerCount}',
            changeLabel:
                l10n?.adminKpiShopManagedOnly ?? 'Shop-managed (KPI only)',
            icon: Icons.storefront_rounded,
            accentColor: neutral,
          ),
          _tappable(
            onTap: () => context.go(RouteNames.adminBlacklist),
            child: AdminKpiCard(
              title: l10n?.adminKpiBlacklisted ?? 'Blacklisted',
              value: '${stats.blacklistedCount}',
              changeLabel: l10n?.admin2_navBlacklist ?? 'Blacklist',
              icon: Icons.gpp_bad_rounded,
              accentColor: warning,
            ),
          ),
        ]),
        const SizedBox(height: 20),
        _sectionHeader(
          context,
          l10n?.adminKpiSectionBookingsSupport ?? 'Bookings & Support',
        ),
        _kpiGrid(context, [
          _tappable(
            onTap: () => context.go(RouteNames.adminBookings),
            child: AdminKpiCard(
              title: l10n?.admin2_dashboardKpiBookings ?? 'Active bookings',
              value: '${stats.activeBookingCount}',
              changeLabel:
                  '${stats.onlineBookingCount} ${l10n?.adminKpiOnlineBookings ?? 'Online Bookings'}',
              icon: Icons.calendar_month_rounded,
              accentColor: success,
            ),
          ),
          AdminKpiCard(
            title: l10n?.adminKpiWalkInBookings ?? 'Walk-in Bookings',
            value: '${stats.walkInBookingCount}',
            changeLabel:
                l10n?.adminKpiShopManagedOnly ?? 'Shop-managed (KPI only)',
            icon: Icons.receipt_long_rounded,
            accentColor: neutral,
          ),
          _tappable(
            onTap: () => context.go(RouteNames.adminDisputes),
            child: AdminKpiCard(
              title: l10n?.admin2_dashboardKpiDisputes ?? 'Open disputes',
              value: '${stats.openDisputeCount}',
              changeLabel: l10n?.admin2_dashboardKpiDisputesNote ??
                  'Awaiting a decision',
              icon: Icons.report_problem_outlined,
              accentColor: warning,
            ),
          ),
          _tappable(
            onTap: () => context.go(RouteNames.adminTickets),
            child: AdminKpiCard(
              title: l10n?.admin2_dashboardKpiTickets ?? 'Open support tickets',
              value: '${stats.openTicketCount}',
              changeLabel:
                  l10n?.admin2_dashboardKpiTicketsNote ?? 'Awaiting a reply',
              icon: Icons.support_agent_rounded,
              accentColor: info,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _kpiGrid(BuildContext context, List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            columnsFor<int>(context, compact: 2, medium: 2, expanded: 4);
        final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) => SizedBox(width: width, child: c)).toList(),
        );
      },
    );
  }

  Widget _tappable({VoidCallback? onTap, required Widget child}) {
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}
