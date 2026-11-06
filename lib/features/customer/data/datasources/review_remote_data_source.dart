import 'package:cloud_firestore/cloud_firestore.dart';

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
      if (customerName != null) 'customerName': customerName,
      if (vehicleName != null) 'vehicleName': vehicleName,
      'shopRating': shopRating,
      'vehicleRating': vehicleRating,
      'customerComment': (comment ?? '').trim(),
      'customerRatedAt': DateTime.now().toIso8601String(),
    };
    return _save(bookingId, data, serverTimestamp: true);
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
      return false;
    }
  }

  /// The review document for a booking, if either side has rated it.
  Future<Map<String, dynamic>?> getReview(String bookingId) async {
    final firestore = _resolvedFirestore;
    if (firestore != null) {
      try {
        final doc =
            await firestore.collection('reviews').doc(bookingId).get();
        if (doc.data() != null) return doc.data();
      } catch (_) {}
    }
    return _inMemory[bookingId];
  }

  /// Reviews for a customer, newest first. [onlyOwnerRated] keeps
  /// the ones the showroom has rated — the customer's reputation
  /// (H3) is built from those, not from their own ratings.
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
        final reviews = snapshot.docs.map((d) => d.data()).toList();
        return _filteredSorted(reviews, onlyOwnerRated: onlyOwnerRated);
      } catch (_) {}
    }
    final reviews = _inMemory.values
        .where((r) => r['customerId'] == customerId)
        .toList();
    return _filteredSorted(reviews, onlyOwnerRated: onlyOwnerRated);
  }

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
