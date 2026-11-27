import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_platform_data_source.dart';

/// Step 2 — the "Showing only this shop" note above a shop-scoped
/// Cars or Bookings list. The back action lives on AdminShell
/// (see [backToShopDetail]); this is only the note.
///
/// The small shared helpers below are top-level functions, like
/// humanizeStatus in admin_status_chip.dart — they keep the
/// Cars and Bookings views under the 250-line cap.
class AdminScopedListBanner extends StatelessWidget {
  const AdminScopedListBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.storefront_rounded,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(l10n.admin2_filteredToShop,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Step 2 — the AdminShell back action for a shop-scoped list:
/// back to that shop's detail. Null for the global list, which
/// has no back button.
VoidCallback? backToShopDetail(BuildContext context, String? shopId) =>
    shopId == null
        ? null
        : () => context
            .go(RouteNames.adminShopDetail.replaceFirst(':shopId', shopId));

/// Step 2 — the shop scope for the cars list. A null shopId leaves
/// the global list untouched.
List<VehicleEntity> scopedCars(List<VehicleEntity> cars, String? shopId) =>
    shopId == null ? cars : cars.where((v) => v.shopId == shopId).toList();

/// Step 2 — one 200-capped client-side load of the bookings, cut
/// to one shop. There is NO server-side shop filter: no
/// shopId+pickupTime composite index exists in
/// firestore.indexes.json (and the 13 new indexes are undeployed),
/// so a server query would fail at runtime.
Future<List<BookingModel>> loadShopBookings(
        AdminPlatformDataSource ds, String shopId) async =>
    (await ds.getBookings(status: 'all'))
        .where((b) => b.shopId == shopId)
        .toList();

/// Step 2 — status filter, search and sort over the in-memory
/// shop list: the same case-insensitive "contains" fields as
/// [AdminPlatformDataSource.searchBookings].
List<BookingModel> scopedBookings(
    List<BookingModel> base, String status, String query, String sort) {
  final needle = query.trim().toLowerCase();
  final filtered = base.where((b) {
    final matchesStatus = status == 'all' || b.status == status;
    final matchesQuery = needle.isEmpty ||
        b.bookingId.toLowerCase().contains(needle) ||
        (b.customerName ?? '').toLowerCase().contains(needle) ||
        (b.vehicleName ?? '').toLowerCase().contains(needle) ||
        (b.shopName ?? '').toLowerCase().contains(needle);
    return matchesStatus && matchesQuery;
  }).toList();
  return AdminPlatformDataSource.sortBookings(filtered, sort);
}
