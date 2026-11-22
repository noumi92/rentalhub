import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/di/injection_container.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';

/// H4: the real reviews store. One document per booking —
/// `reviews/{bookingId}` — so a trip can be rated once by each side:
/// the customer rates the showroom/vehicle, the showroom rates the
/// customer (the mirror half in OwnerCustomerRatingView). Both sides
/// merge into the same document.
///
/// Follows the repo's data-source pattern (SecurityDepositDataSource,
/// DisputeRemoteDataSource): the Firestore instance is resolved
/// lazily so construction never throws when Firebase isn't
/// initialised (widget tests), and an in-memory store covers the
/// offline case. The submit methods return whether the cloud write
/// actually happened, so the UI can say so honestly instead of
/// claiming a rating is saved when it only lives on the device.
class ReviewRemoteDataSource {
  ReviewRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final Map<String, Map<String, dynamic>> _inMemory = {};

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// The customer's rating of the showroom and vehicle for [bookingId].
  /// Returns true when the review reached Firestore.
  ///
  /// F-M15 (admin audit 2026-11-14): an `edit_requested` review is
  /// editable again from the rate-trip screen, and submitting the
  /// edit clears the request (`moderation_status` back to 'visible')
  /// — the edit IS the compliance. A `warned` review needs no
  /// action: the warning is shown to the customer on the same
  /// screen, and re-submitting it is a no-op for moderation.
  Future<bool> submitCustomerReview({
    required String bookingId,
    required String shopId,
    required String customerId,
    String? customerName,
    String? vehicleName,
    required int shopRating,
    required int vehicleRating,
    String? comment,
  }) async {
    final data = <String, dynamic>{
      'bookingId': bookingId,
      'shopId': shopId,
      'customerId': customerId,
      'reviewer_uid': customerId,
      if (customerName != null) 'customerName': customerName,
      if (vehicleName != null) 'vehicleName': vehicleName,
      'shopRating': shopRating,
      'vehicleRating': vehicleRating,
      'customerComment': (comment ?? '').trim(),
      'customerRatedAt': DateTime.now().toIso8601String(),
    };
    if (_inMemory[bookingId]?['moderation_status'] == 'edit_requested') {
      data['moderation_status'] = 'visible';
      data['moderation_reason'] = '';
      data['edited_after_moderation_request'] = true;
    }
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        final doc =
            await firestore.collection('reviews').doc(bookingId).get();
        if (doc.data()?['moderation_status'] == 'edit_requested') {
          data['moderation_status'] = 'visible';
          data['moderation_reason'] = '';
          data['edited_after_moderation_request'] = true;
        }
      } catch (_) {}
    }
    final ok = await _save(bookingId, data, serverTimestamp: true);
    if (shopId.isNotEmpty && sl.isRegistered<NotificationDataSource>()) {
      try {
        await sl<NotificationDataSource>().createNotification(
          shopId: shopId,
          title: 'New customer review',
          body:
              '${customerName ?? 'A customer'} rated ${vehicleName ?? '#$bookingId'} ($shopRating★ showroom, $vehicleRating★ vehicle).',
          type: 'new_review',
          bookingId: bookingId,
        );
      } catch (_) {}
    }
    return ok;
  }

  /// The showroom's rating of the customer for [bookingId].
  /// Returns true when the review reached Firestore.
  Future<bool> submitOwnerReview({
    required String bookingId,
    required String shopId,
    required String customerId,
    required int punctualityRating,
    required int careRating,
    required int behaviorRating,
    String? comment,
  }) async {
    final data = <String, dynamic>{
      'bookingId': bookingId,
      'shopId': shopId,
      'customerId': customerId,
      'reviewer_uid': shopId,
      'punctualityRating': punctualityRating,
      'careRating': careRating,
      'behaviorRating': behaviorRating,
      'ownerComment': (comment ?? '').trim(),
      'ownerRatedAt': DateTime.now().toIso8601String(),
    };
    return _save(bookingId, data, serverTimestamp: true);
  }

  Future<bool> _save(
    String bookingId,
    Map<String, dynamic> data, {
    required bool serverTimestamp,
  }) async {
    final existing = _inMemory[bookingId] ?? {};
    _inMemory[bookingId] = {...existing, ...data};
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final cloudData = Map<String, dynamic>.from(data);
      if (serverTimestamp) {
        // Keep the server clock for the rating time on the cloud copy.
        if (cloudData.containsKey('customerRatedAt')) {
          cloudData['customerRatedAt'] = FieldValue.serverTimestamp();
        }
        if (cloudData.containsKey('ownerRatedAt')) {
          cloudData['ownerRatedAt'] = FieldValue.serverTimestamp();
        }
      }
      await firestore
          .collection('reviews')
          .doc(bookingId)
          .set(cloudData, SetOptions(merge: true));
      return true;
    } catch (_) {
      // Queue for offline sync so ratings are not lost on app restart.
      try {
        if (sl.isRegistered<OfflineSyncQueue>()) {
          await sl<OfflineSyncQueue>().enqueue(
            kind: 'firestore_set',
            entityId: 'reviews/$bookingId',
            payload: {
              'collection': 'reviews',
              'docId': bookingId,
              'data': data,
              'merge': true,
            },
          );
        }
      } catch (_) {}
      return false;
    }
  }

  /// The review document for a booking, if either side has rated it.
  /// Null when the admin hid the review (`moderation_status:
  /// 'hidden'`) — a hidden review is not shown back to the customer.
  Future<Map<String, dynamic>?> getReview(String bookingId) async {
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        final doc =
            await firestore.collection('reviews').doc(bookingId).get();
        final data = doc.data();
        if (data != null && _isNotHidden(data)) return data;
        if (data != null) return null;
      } catch (_) {}
    }
    final stored = _inMemory[bookingId];
    if (stored != null && _isNotHidden(stored)) return stored;
    return null;
  }

  /// Reviews for a customer, newest first. [onlyOwnerRated] keeps
  /// the ones the showroom has rated — the customer's reputation
  /// (H3) is built from those, not from their own ratings.
  ///
  /// Admin-integration audit (2026-11-10): a review the admin hid
  /// (`moderation_status: 'hidden'`) is excluded here — on both the
  /// live and the in-memory paths — so a hidden review stops
  /// counting toward the customer's reputation and trust score.
  /// Before this, the admin moderation decision had no reader: the
  /// status was written and never honoured anywhere in the app.
  Future<List<Map<String, dynamic>>> getCustomerReviews(
    String customerId, {
    bool onlyOwnerRated = false,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore
            .collection('reviews')
            .where('customerId', isEqualTo: customerId)
            .get();
        final reviews = snapshot.docs
            .map((d) => d.data())
            .where(_isNotHidden)
            .toList();
        return _filteredSorted(reviews, onlyOwnerRated: onlyOwnerRated);
      } catch (_) {}
    }
    final reviews = _inMemory.values
        .where((r) => r['customerId'] == customerId)
        .where(_isNotHidden)
        .toList();
    return _filteredSorted(reviews, onlyOwnerRated: onlyOwnerRated);
  }

  /// A review counts unless the admin explicitly hid it
  /// (`moderation_status: 'hidden'`). Public so the moderation
  /// contract is unit-testable without Firestore.
  static bool isHiddenReview(Map<String, dynamic> review) =>
      review['moderation_status'] == 'hidden';

  /// F-M15: the moderation states the admin sets actually mean
  /// something to the customer now. `edit_requested` re-opens the
  /// rate-trip screen for editing (see CustomerRateTripView);
  /// `warned` shows a warning banner on the same screen. Both are
  /// read from the raw review map the customer already loads.
  static String moderationStatusOf(Map<String, dynamic> review) =>
      (review['moderation_status'] as String?) ?? 'visible';

  static bool isEditRequested(Map<String, dynamic> review) =>
      moderationStatusOf(review) == 'edit_requested';

  static bool isWarned(Map<String, dynamic> review) =>
      moderationStatusOf(review) == 'warned';

  static String moderationReasonOf(Map<String, dynamic> review) =>
      (review['moderation_reason'] as String?) ?? '';

  /// A review counts unless the admin explicitly hid it.
  static bool _isNotHidden(Map<String, dynamic> review) =>
      !isHiddenReview(review);

  List<Map<String, dynamic>> _filteredSorted(
    List<Map<String, dynamic>> reviews, {
    required bool onlyOwnerRated,
  }) {
    if (onlyOwnerRated) {
      reviews.removeWhere((r) => r['ownerRatedAt'] == null);
    }
    reviews.sort((a, b) => _ratedAt(b).compareTo(_ratedAt(a)));
    return reviews;
  }

  DateTime _ratedAt(Map<String, dynamic> review) {
    final raw = review['ownerRatedAt'] ?? review['customerRatedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime(1970);
    return DateTime(1970);
  }
}
