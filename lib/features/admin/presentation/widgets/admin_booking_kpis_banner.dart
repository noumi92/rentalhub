import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import 'admin_mini_kpi_strip.dart';
import 'admin_status_chip.dart';

/// Read-only Booking KPIs & historical status summary (numbers only —
/// no booking detail records) shown at the top of Disputes & Reviews.
class AdminBookingKpisBanner extends StatefulWidget {
  const AdminBookingKpisBanner({super.key});

  @override
  State<AdminBookingKpisBanner> createState() => _AdminBookingKpisBannerState();
}

class _AdminBookingKpisBannerState extends State<AdminBookingKpisBanner> {
  PlatformStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!sl.isRegistered<AdminRemoteDataSource>()) return;
      final stats = await sl<AdminRemoteDataSource>().getPlatformStats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final success = adminStatusColor(context, AdminStatusTone.success);
    final warning = adminStatusColor(context, AdminStatusTone.warning);
    final total = stats.onlineBookingCount + stats.walkInBookingCount;

    return AdminMiniKpiStrip(
      items: [
        AdminMiniKpi(
          label: l10n?.admin2_navBookings ?? 'Total Bookings',
          value: '$total',
          icon: Icons.analytics_outlined,
        ),
        AdminMiniKpi(
          label: l10n?.admin2_dashboardKpiBookings ?? 'Active',
          value: '${stats.activeBookingCount}',
          icon: Icons.directions_car_rounded,
          accentColor: success,
        ),
        AdminMiniKpi(
          label: l10n?.adminKpiOnlineBookings ?? 'Online',
          value: '${stats.onlineBookingCount}',
          icon: Icons.public_rounded,
        ),
        AdminMiniKpi(
          label: l10n?.adminKpiWalkInBookings ?? 'Walk-in',
          value: '${stats.walkInBookingCount}',
          icon: Icons.storefront_rounded,
          muted: true,
        ),
        AdminMiniKpi(
          label: l10n?.admin2_dashboardKpiDisputes ?? 'Open Disputes',
          value: '${stats.openDisputeCount}',
          icon: Icons.gavel_rounded,
          accentColor: stats.openDisputeCount > 0 ? warning : null,
        ),
      ],
    );
  }
}
