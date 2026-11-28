import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../data/datasources/admin_people_data_source.dart';
import 'admin_mini_kpi_strip.dart';
import 'admin_qr_code_row.dart';
import 'admin_status_chip.dart';

/// Phase 4 (4.4a) — the customer detail's identity header,
/// extracted from [AdminCustomerDetailView] so the view stays under
/// the 250-line cap with its sticky action bar: the name, contact
/// line, super-admin-only QR number, and the blacklisted chip.
class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
    required this.detail,
    required this.isSuperAdmin,
    required this.qrCode,
  });

  final CustomerDetail detail;
  final bool isSuperAdmin;
  final String? qrCode;

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.customer.name,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            l10n.admin2_customerDetailContact(
                detail.customer.phone,
                detail.customer.cnic ?? l10n.admin2_notOnFile,
                humanizeStatus(detail.customer.source, l10n)),
            style: const TextStyle(fontSize: 13)),
        AdminQrCodeRow(isSuperAdmin: isSuperAdmin, qrCode: qrCode),
        const SizedBox(height: 8),
        if (detail.isBlacklisted)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20)),
            // Item 4: the readable danger text token is ~6.1:1 on
            // the error container.
            child: Text(l10n.admin2_customerDetailBlacklisted,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.dangerTextFor(
                        Theme.of(context).brightness))),
          ),
        const SizedBox(height: 8),
        AdminMiniKpiStrip(items: [
          AdminMiniKpi(
            label: l10n.admin2_trustTitle,
            value: detail.trustBreakdown.total.toStringAsFixed(1),
            icon: Icons.verified_user_rounded,
          ),
          AdminMiniKpi(
            label: l10n.admin2_customerDetailTabBookings,
            value: '${detail.completedTrips}',
            icon: Icons.directions_car_rounded,
          ),
          AdminMiniKpi(
            label: l10n.admin2_shopDetailRating,
            value: detail.meanOwnerRating == null
                ? '—'
                : detail.meanOwnerRating!.toStringAsFixed(1),
            icon: Icons.star_rounded,
          ),
          AdminMiniKpi(
            label: 'KYC',
            value: humanizeStatus(detail.kycStatus, l10n),
            icon: Icons.badge_rounded,
          ),
        ]),
      ],
    );
  }
}

/// Phase 4 (4.4a) — the Watchlist / Blacklist buttons as the
/// customer detail's sticky action bar, so the flag actions are
/// reachable from every tab (they used to live only at the bottom
/// of the Notes tab, under the composer). The Notes tab keeps its
/// own copies beside the composer.
class CustomerDetailStickyActions extends StatelessWidget {
  const CustomerDetailStickyActions({
    super.key,
    required this.detail,
    required this.isWorking,
    required this.onWatchlist,
    required this.onBlacklist,
  });

  final CustomerDetail detail;
  final bool isWorking;
  final VoidCallback onWatchlist;
  final VoidCallback onBlacklist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    final watchlist = OutlinedButton(
      onPressed: isWorking ? null : onWatchlist,
      style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48)),
      child: Text(detail.isWatchlisted
          ? l10n?.admin2_watchlistRemove ?? 'Remove from watchlist'
          : l10n?.admin2_watchlistAdd ?? 'Add to watchlist'),
    );
    final blacklist = FilledButton(
      style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          minimumSize: const Size(0, 48)),
      onPressed: isWorking ? null : onBlacklist,
      child: Text(l10n?.admin2_custActionBlacklist ?? 'Report to blacklist'),
    );
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          watchlist,
          const SizedBox(height: 8),
          blacklist,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: watchlist),
        const SizedBox(width: 12),
        Expanded(child: blacklist),
      ],
    );
  }
}
