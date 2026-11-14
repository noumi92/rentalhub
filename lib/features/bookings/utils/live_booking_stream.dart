import 'dart:async';

import '../../../core/di/injection_container.dart';
import '../../finance/data/datasources/security_deposit_data_source.dart';
import '../data/datasources/booking_remote_data_source.dart';
import '../domain/entities/booking_entity.dart';

/// Live updates (Item 2): one-line live subscription to a bookings
/// stream, for views. Resolves the data source from the locator and
/// returns the subscription, or null when it cannot be resolved
/// (tests without DI) — the caller keeps its one-time load as the
/// first paint and its retry path. [onError] defaults to ignoring
/// the error, so the last good data stays on screen.
StreamSubscription<List<BookingEntity>>? subscribeLiveBookings(
  Stream<List<BookingEntity>> Function(BookingRemoteDataSource ds) select,
  void Function(List<BookingEntity> list) onData, {
  void Function()? onError,
}) {
  try {
    return select(sl<BookingRemoteDataSource>()).listen(
      onData,
      onError: (_) => onError?.call(),
    );
  } catch (_) {
    return null;
  }
}

/// The dashboard's settle rate over a bookings list: the share of
/// completed bookings whose deposit is settled. Null when there are
/// no completed bookings.
Future<double?> settleRateFor(List<BookingEntity> bookings) async {
  final completed = bookings.where((b) => b.status == 'completed').toList();
  if (completed.isEmpty) return null;
  final depositDs = sl<SecurityDepositDataSource>();
  var settled = 0;
  for (final b in completed) {
    final d = await depositDs.getByBookingId(b.bookingId);
    if (d != null && d.status != 'collected') settled++;
  }
  return settled / completed.length;
}
