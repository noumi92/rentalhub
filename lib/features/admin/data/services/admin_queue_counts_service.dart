import '../../../../core/di/injection_container.dart';
import '../datasources/admin_platform_data_source.dart';
import '../datasources/admin_remote_data_source.dart';
import '../datasources/admin_shops_data_source.dart';

/// Phase 2 (2.1/2.2) — the live counts for the six review queues
/// (Approvals, KYC Review, Cars, Disputes, Reviews, Support), shared
/// by the grouped sidebar badges and the Queues hub.
///
/// The four Firestore `count()` aggregates come from
/// [AdminRemoteDataSource.getPlatformStats] (the same definitions the
/// dashboard shows, so the badges and the dashboard never disagree:
/// approvals are shops with `verification_status == 'pending'`, KYC
/// is `submitted` + `resubmitted`, disputes are any non-resolved
/// dispute, tickets are `status == 'open'`). Cars and reviews have
/// no single aggregate — a car is pending while its car-review doc
/// is missing or `pending` (the same rule the Cars view filters on),
/// and a review is pending while it carries an auto-check signal and
/// is still `visible` (unmoderated).
///
/// The counts are cached for 60 seconds: the sidebar is rebuilt on
/// every navigation, and without the cache each navigation would
/// re-read the collections. A stale count is harmless here — the
/// queue screens themselves always load live — so a short TTL is
/// the right trade-off, and callers can force a refresh.
class AdminQueueCounts {
  const AdminQueueCounts({
    required this.approvals,
    required this.kyc,
    required this.cars,
    required this.disputes,
    required this.reviews,
    required this.tickets,
  });

  final int approvals;
  final int kyc;
  final int cars;
  final int disputes;
  final int reviews;
  final int tickets;
}

class AdminQueueCountsService {
  AdminQueueCountsService({
    AdminRemoteDataSource? remote,
    AdminShopsDataSource? shops,
    AdminPlatformDataSource? platform,
  })  : _remote = remote,
        _shops = shops,
        _platform = platform;

  final AdminRemoteDataSource? _remote;
  final AdminShopsDataSource? _shops;
  final AdminPlatformDataSource? _platform;

  static const _cacheTtl = Duration(seconds: 60);
  AdminQueueCounts? _cached;
  DateTime? _cachedAt;

  AdminRemoteDataSource get _resolvedRemote {
    try {
      return _remote ?? sl<AdminRemoteDataSource>();
    } catch (_) {
      return AdminRemoteDataSource();
    }
  }

  AdminShopsDataSource get _resolvedShops {
    try {
      return _shops ?? sl<AdminShopsDataSource>();
    } catch (_) {
      return AdminShopsDataSource();
    }
  }

  AdminPlatformDataSource get _resolvedPlatform {
    try {
      return _platform ?? sl<AdminPlatformDataSource>();
    } catch (_) {
      return AdminPlatformDataSource();
    }
  }

  Future<AdminQueueCounts> getCounts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cached!;
    }
    final stats = await _resolvedRemote.getPlatformStats();
    final cars = await _resolvedShops.getCars();
    final carReviews = await _resolvedShops.getCarReviews();
    final pendingCars = cars
        .where((v) => (carReviews[v.vehicleId]?.status ?? 'pending') == 'pending')
        .length;
    final reviews = await _resolvedPlatform.getReviews();
    final pendingReviews = reviews
        .where((r) =>
            r.signals.isNotEmpty && r.moderationStatus == 'visible')
        .length;
    final counts = AdminQueueCounts(
      approvals: stats.pendingShopCount,
      kyc: stats.pendingKycCount,
      cars: pendingCars,
      disputes: stats.openDisputeCount,
      reviews: pendingReviews,
      tickets: stats.openTicketCount,
    );
    _cached = counts;
    _cachedAt = DateTime.now();
    return counts;
  }
}
