import 'dart:async';

import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/live_booking_stream.dart';

/// Live updates (Item 2): the owner dashboard's bookings
/// subscription — the KPIs, schedule and ledger follow the shop's
/// bookings stream, with the settle rate recomputed per emission.
/// The view passes plain callbacks (it owns the mounted checks);
/// [dispose] cancels the stream. A dead stream (error) clears the
/// subscription, so the dashboard's refresh button re-subscribes.
class DashboardLiveBookings {
  StreamSubscription<List<BookingEntity>>? _sub;
  int _gen = 0;

  /// Returns false when the bookings data source cannot be resolved,
  /// so the view can render its error state instead of an eternal
  /// spinner; true when the subscription is live (or already was).
  bool subscribe({
    required String shopId,
    required void Function(List<BookingEntity> bookings) onBookings,
    required void Function(double? settleRate) onSettleRate,
  }) {
    if (_sub != null) return true;
    _sub = subscribeLiveBookings(
      (ds) => ds.streamShopBookings(shopId),
      (list) {
        onBookings(list);
        final gen = ++_gen;
        unawaited(settleRateFor(list).then((rate) {
          if (gen == _gen) onSettleRate(rate);
        }));
      },
      onError: () => _sub = null,
    );
    return _sub != null;
  }

  void dispose() => _sub?.cancel();
}
