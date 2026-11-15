import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/entities/booking_entity.dart';

/// Team B (UI/UX audit 2026-11-15, FG-4 / FG-1): the booking request
/// time. Firestore writes `createdAt` (server timestamp) on every
/// booking, but [BookingEntity] / [BookingModel] drop the field, so
/// no screen can say how long a request has waited. The proper fix
/// is a `createdAt` field on the entity + model (data-layer change,
/// outside this batch's file list); until then this helper reads the
/// raw `bookings/{id}` document's `createdAt` directly — one doc read
/// per booking, cached for the session so a list re-render never
/// re-reads it. Never invents a time: an unknown / missing timestamp
/// stays null and the caller renders no wait line.
///
/// Callers that already hold the entities (triage view, dashboard)
/// fetch once per stream emission and sort on the result; cards that
/// render standalone read the session cache synchronously via
/// [BookingRequestTimes.cached] (populated by the owning view's fetch)
/// or take an explicit `requestedAt` in tests.
class BookingRequestTimes {
  static final Map<String, DateTime?> _cache = {};

  /// The cached request time for [bookingId], or null when it was
  /// never fetched (or the document has no timestamp).
  static DateTime? cached(String bookingId) => _cache[bookingId];

  /// Test-only: seed the cache without Firestore.
  static void seedForTest(Map<String, DateTime?> times) {
    _cache.addAll(times);
  }

  /// Test-only: clear the session cache.
  static void clearForTest() => _cache.clear();

  /// Fetch the request times for [bookingIds] (uncached ids only)
  /// and return the times for all of them. Never throws — a missing
  /// Firestore or a failed read leaves those ids null.
  static Future<Map<String, DateTime?>> fetch(
    Iterable<String> bookingIds, {
    FirebaseFirestore? firestore,
  }) async {
    final wanted = bookingIds.where((id) => !_cache.containsKey(id)).toList();
    if (wanted.isNotEmpty) {
      try {
        final fs = firestore ?? FirebaseFirestore.instance;
        final snaps = await Future.wait(
          wanted.map((id) => fs.collection('bookings').doc(id).get()),
        );
        for (var i = 0; i < wanted.length; i++) {
          _cache[wanted[i]] = _parseCreatedAt(snaps[i].data()?['createdAt']);
        }
      } catch (_) {
        for (final id in wanted) {
          _cache[id] = null;
        }
      }
    }
    return {for (final id in bookingIds) id: _cache[id]};
  }

  static DateTime? _parseCreatedAt(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}

/// Split a wait into days / hours / minutes for the localised
/// duration keys (`waitDurationDays` / `waitDurationHm` /
/// `waitDurationMinutes`).
({int days, int hours, int minutes}) waitParts(Duration wait) {
  final totalMinutes = wait.inMinutes;
  return (
    days: totalMinutes ~/ (24 * 60),
    hours: (totalMinutes ~/ 60) % 24,
    minutes: totalMinutes % 60,
  );
}

/// Localised compact duration ("6h 12m", "45m", "2d 3h") — no
/// "Waiting" prefix, so callers can wrap it ("Waiting …" on a card,
/// "Oldest wait: …" on the dashboard).
String waitDurationLabel(AppLocalizations l10n, Duration wait) {
  final parts = waitParts(wait);
  if (parts.days > 0) {
    return l10n.waitDurationDays(parts.days, parts.hours);
  }
  if (parts.hours > 0) {
    return l10n.waitDurationHm(parts.hours, parts.minutes);
  }
  return l10n.waitDurationMinutes(parts.minutes);
}

/// Oldest-first order by request time. Bookings with an unknown
/// request time sort last (never invented, never first) and keep
/// their relative order.
List<BookingEntity> sortByRequestAgeOldestFirst(
  List<BookingEntity> bookings,
  Map<String, DateTime?> requestTimes,
) {
  final indexed = bookings.indexed.toList();
  indexed.sort((a, b) {
    final ta = requestTimes[a.$2.bookingId];
    final tb = requestTimes[b.$2.bookingId];
    if (ta == null && tb == null) return a.$1.compareTo(b.$1);
    if (ta == null) return 1;
    if (tb == null) return -1;
    final byTime = ta.compareTo(tb);
    return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
  });
  return indexed.map((e) => e.$2).toList();
}

/// The longest current wait among [bookings] (now minus the oldest
/// known request time), or null when no request time is known.
Duration? oldestWaitFor(
  Iterable<BookingEntity> bookings,
  Map<String, DateTime?> requestTimes, {
  DateTime? now,
}) {
  DateTime? oldest;
  for (final b in bookings) {
    final t = requestTimes[b.bookingId];
    if (t == null) continue;
    if (oldest == null || t.isBefore(oldest)) oldest = t;
  }
  if (oldest == null) return null;
  return (now ?? DateTime.now()).difference(oldest);
}
