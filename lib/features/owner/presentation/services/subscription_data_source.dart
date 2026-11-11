import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import 'subscription_plans.dart';

export 'subscription_plans.dart';

/// Subscription data (deck Step 6, S1–S6) — gated on D1 (Play Console).
///
/// The deck's plan picker is built, but Google Play billing is NOT
/// connected: the only payment path is the existing manual bank-transfer
/// flow (IBAN + transaction ID -> `subscription_requests`, admin
/// approves). No purchase, trial date, payment method or billing date
/// is ever invented here — dates are shown only when a stored field
/// actually carries them.
class ShopSubscriptionState {
  final String tier;
  final String? status;
  final DateTime? trialEndsAt;
  final DateTime? nextBillingAt;
  final bool suspended;
  final String? suspensionReason;
  final String? pendingTier;

  const ShopSubscriptionState({
    required this.tier,
    this.status,
    this.trialEndsAt,
    this.nextBillingAt,
    this.suspended = false,
    this.suspensionReason,
    this.pendingTier,
  });

  /// A payment issue exists only when the shop is suspended (admin-set)
  /// or a subscription request was rejected — never by default.
  bool get hasPaymentIssue =>
      suspended ||
      (suspensionReason != null && suspensionReason!.isNotEmpty);
}

class SubscriptionRequestRecord {
  final String tier;
  final String billingPeriod;
  final int price;
  final String transactionId;
  final String status;
  final DateTime? createdAt;

  const SubscriptionRequestRecord({
    required this.tier,
    required this.billingPeriod,
    required this.price,
    required this.transactionId,
    required this.status,
    this.createdAt,
  });

  factory SubscriptionRequestRecord.fromMap(Map<String, dynamic> data) {
    final created = data['createdAt'];
    return SubscriptionRequestRecord(
      tier: (data['tier'] as String?) ?? 'free',
      billingPeriod: (data['billingPeriod'] as String?) ?? 'monthly',
      price: (data['price'] as num?)?.toInt() ?? 0,
      transactionId: (data['transactionId'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

class SubscriptionDataSource {
  final FirebaseFirestore? _firestore;

  SubscriptionDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  DateTime? _asDate(dynamic value) =>
      value is Timestamp ? value.toDate() : null;

  Future<ShopSubscriptionState> getShopSubscription(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const ShopSubscriptionState(tier: 'free');
    try {
      final doc = await fs.collection('shops').doc(shopId).get();
      final data = doc.data() ?? {};
      String? pendingTier;
      try {
        final pending = await fs
            .collection('subscription_requests')
            .where('shopId', isEqualTo: shopId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        pendingTier =
            pending.docs.firstOrNull?.data()['tier'] as String?;
      } catch (_) {
        pendingTier = null;
      }
      return ShopSubscriptionState(
        tier: normalizeSubscriptionTier(
            data['subscriptionTier'] as String?),
        status: data['subscriptionStatus'] as String?,
        trialEndsAt: _asDate(data['trialEndsAt']),
        nextBillingAt: _asDate(data['nextBillingAt']),
        suspended: (data['suspended'] as bool?) ?? false,
        suspensionReason: data['suspensionReason'] as String?,
        pendingTier: pendingTier,
      );
    } catch (_) {
      return const ShopSubscriptionState(tier: 'free');
    }
  }

  Future<List<SubscriptionRequestRecord>> getSubscriptionHistory(
      String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const [];
    try {
      final snap = await fs
          .collection('subscription_requests')
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => SubscriptionRequestRecord.fromMap(d.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> submitSubscriptionRequest({
    required String shopId,
    required String tier,
    required String billingPeriod,
    required int price,
    required String transactionId,
    required bool isTrial,
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) throw StateError('Firestore is not available.');
    await fs.collection('subscription_requests').add({
      'shopId': shopId,
      'tier': tier,
      'billingPeriod': billingPeriod,
      'price': price,
      'transactionId': transactionId,
      'isTrial': isTrial,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Shop-id mismatch (2026-11-11): vehicles are stored under the shop
  /// DOCUMENT id, but callers pass the owner's UID — a plain
  /// `shopId == shopId` count misses every new car. Delegates to the
  /// fleet data source, whose count matches both id forms.
  Future<int> getFleetCount(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return 0;
    try {
      return await FleetRemoteDataSource(firestore: fs)
          .getActiveVehicleCount(shopId);
    } catch (_) {
      return 0;
    }
  }

  /// Staff logins are read from the `staff` collection (worker C owns
  /// the write side); until it exists this honestly reads 0.
  Future<int> getStaffCount(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return 0;
    try {
      final snap = await fs
          .collection('staff')
          .where('shopId', isEqualTo: shopId)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
