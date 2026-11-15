import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/utils/shop_id_resolution.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';

/// Audit §5 (P2-5): the approval gate for adding vehicles. The shop's
/// `verificationStatus` is read from the `shops` doc; while it is
/// 'pending' the owner cannot open the add-vehicle flow and is shown
/// an honest message with a link to the onboarding status step. A
/// failed read (offline, no Firebase in tests) fails OPEN — it must
/// never strand an approved owner — and any other status allows.
class FleetAddGate {
  static Future<bool> ensureApproved(BuildContext context, String shopId) async {
    String? status;
    try {
      // Shop-id linking (2026-11-15): callers pass the owner's bare
      // UID, but the shops document is `shop_<uid>` — the bare read
      // always missed, so a pending-verification shop was never
      // blocked from adding vehicles. Resolve the doc id first.
      final fs = FirebaseFirestore.instance;
      final doc = await fs
          .collection('shops')
          .doc(await canonicalShopId(fs, shopId))
          .get();
      final data = doc.data();
      status = (data?['verificationStatus'] ?? data?['verification_status']) as String?;
    } catch (_) {
      status = null;
    }
    if (status != 'pending') return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final goStatus = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fleetAddBlockedTitle),
        content: Text(l10n.fleetAddBlockedBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.fleetAddBlockedViewStatus)),
        ],
      ),
    );
    if (goStatus == true && context.mounted) {
      // The registrar wires `?step=status` to OwnerOnboardingView's
      // initialStep (6); until then this opens onboarding at step 1.
      context.push('${RouteNames.ownerOnboarding}?step=status');
    }
    return false;
  }
}

/// Phone bug: the card's "Edit rates" / "Booking calendar" buttons
/// are plain OutlinedButtons (not DebouncedButtons), so a double-tap
/// pushed the same parameterized location twice. go_router keys a
/// page by its route pattern, so the branch Navigator then held two
/// pages with one key and threw its duplicate-key assertion (debug
/// red screen on "Manage rates"). Guard every push from the fleet
/// view: the same location twice within 500 ms is one navigation.
class PushOnceGuard {
  String? _lastPushed;
  DateTime? _lastPushAt;

  Future<Object?> push(BuildContext context, String location) {
    final now = DateTime.now();
    if (_lastPushed == location &&
        _lastPushAt != null &&
        now.difference(_lastPushAt!) < const Duration(milliseconds: 500)) {
      return Future<Object?>.value();
    }
    _lastPushed = location;
    _lastPushAt = now;
    return context.push<Object?>(location);
  }
}

/// Audit §5 (O05/O30): the active rental behind each fleet card — the
/// return date of the vehicle's `active` booking, if it has one.
/// Firestore when available; an empty map on any failure, so the card
/// simply omits the "On Rent until" line instead of guessing a date.
class FleetRentalLookup {
  static Future<Map<String, DateTime>> activeRentalsByVehicle(String shopId) async {
    try {
      final bookings = await sl<BookingRemoteDataSource>().getShopBookings(shopId);
      return activeRentalsFromBookings(bookings);
    } catch (_) {
      return {};
    }
  }

  /// The pure form of [activeRentalsByVehicle], over an
  /// already-loaded list — for live subscribers that recompute on
  /// every bookings emission instead of re-fetching.
  static Map<String, DateTime> activeRentalsFromBookings(
      List<BookingEntity> bookings) {
    final result = <String, DateTime>{};
    for (final b in bookings) {
      if (b.status != 'active') continue;
      final existing = result[b.vehicleId];
      if (existing == null || b.returnTime.isAfter(existing)) {
        result[b.vehicleId] = b.returnTime;
      }
    }
    return result;
  }

  /// Live updates (Item 2): the same map as a stream — a booking
  /// submit or status change re-emits it. Falls back to an empty
  /// map when the data source is unavailable.
  static Stream<Map<String, DateTime>> streamActiveRentalsByVehicle(
      String shopId) {
    try {
      return sl<BookingRemoteDataSource>()
          .streamShopBookings(shopId)
          .map(activeRentalsFromBookings);
    } catch (_) {
      return Stream.value(const <String, DateTime>{});
    }
  }
}
