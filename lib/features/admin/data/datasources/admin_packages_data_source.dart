import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../domain/admin_permissions.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_session.dart';

/// Summary row for a shop's current subscription tier and WhatsApp balance.
class AdminShopPlanRow {
  const AdminShopPlanRow({
    required this.shopId,
    required this.shopName,
    required this.city,
    required this.tier,
    required this.isVerified,
    required this.whatsappBalance,
  });

  final String shopId;
  final String shopName;
  final String city;
  final String tier;
  final bool isVerified;
  final int whatsappBalance;
}

/// One row from `subscription_requests`.
class AdminSubscriptionRequest {
  const AdminSubscriptionRequest({
    required this.requestId,
    required this.shopId,
    required this.shopName,
    required this.tier,
    required this.amount,
    required this.trxId,
    required this.status,
    this.billingPeriod = 'monthly',
    this.reason,
    this.createdAt,
  });

  final String requestId;
  final String shopId;
  final String shopName;
  final String tier;
  final num amount;
  final String trxId;
  final String status;
  final String billingPeriod;
  final String? reason;
  final DateTime? createdAt;

  factory AdminSubscriptionRequest.fromMap(
      String id, Map<String, dynamic> data) {
    return AdminSubscriptionRequest(
      requestId: id,
      shopId: (data['shop_id'] as String? ?? data['shopId'] as String? ?? ''),
      shopName:
          (data['shop_name'] as String? ?? data['shopName'] as String? ?? id),
      tier: (data['tier'] as String? ??
              data['requested_tier'] as String? ??
              'pro')
          .toLowerCase(),
      amount: (data['amount'] as num? ?? data['price'] as num? ?? 0),
      trxId: (data['trx_id'] as String? ??
          data['transaction_id'] as String? ??
          data['reference'] as String? ??
          ''),
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      billingPeriod: (data['billing_period'] as String? ?? 'monthly'),
      reason: data['decision_reason'] as String?,
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
    );
  }
}

/// One row from `credit_purchase_requests`.
class AdminCreditRequest {
  const AdminCreditRequest({
    required this.requestId,
    required this.shopId,
    required this.shopName,
    required this.packName,
    required this.packCredits,
    required this.amount,
    required this.trxId,
    required this.status,
    this.reason,
    this.createdAt,
  });

  final String requestId;
  final String shopId;
  final String shopName;
  final String packName;
  final int packCredits;
  final num amount;
  final String trxId;
  final String status;
  final String? reason;
  final DateTime? createdAt;

  factory AdminCreditRequest.fromMap(String id, Map<String, dynamic> data) {
    return AdminCreditRequest(
      requestId: id,
      shopId: (data['shop_id'] as String? ?? data['shopId'] as String? ?? ''),
      shopName:
          (data['shop_name'] as String? ?? data['shopName'] as String? ?? id),
      packName: (data['pack_name'] as String? ??
          data['packName'] as String? ??
          'WhatsApp Pack'),
      packCredits: (data['credits'] as num? ??
              data['pack_credits'] as num? ??
              data['quantity'] as num? ??
              0)
          .toInt(),
      amount: (data['amount'] as num? ?? data['price'] as num? ?? 0),
      trxId: (data['trx_id'] as String? ??
          data['transaction_id'] as String? ??
          data['reference'] as String? ??
          ''),
      status: (data['status'] as String? ?? 'pending').toLowerCase(),
      reason: data['decision_reason'] as String?,
      createdAt: _parseDate(data['created_at'] ?? data['createdAt']),
    );
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

/// Super Admin & Operations data source for Shop Subscription Plans and
/// WhatsApp Credit Packages.
class AdminPackagesDataSource {
  AdminPackagesDataSource({
    FirebaseFirestore? firestore,
    NotificationDataSource? notifications,
  })  : _firestore = firestore,
        _notifications = notifications;

  final FirebaseFirestore? _firestore;
  final NotificationDataSource? _notifications;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  NotificationDataSource? get _resolvedNotifications {
    if (_notifications != null) return _notifications;
    try {
      return sl<NotificationDataSource>();
    } catch (_) {
      return null;
    }
  }

  Future<List<AdminShopPlanRow>> getShopPlans() async {
    final fs = _resolvedFirestore;
    if (fs == null) return [];
    final results = await Future.wait([
      fs.collection('shops').get(),
      fs.collection('whatsapp_credits').get(),
    ]);
    final shopsSnap = results[0];
    final creditsSnap = results[1];
    final balances = <String, int>{};
    for (final doc in creditsSnap.docs) {
      final b = (doc.data()['balance'] as num? ?? 0).toInt();
      balances[doc.id] = b;
    }
    final rows = shopsSnap.docs.map((doc) {
      final d = doc.data();
      final tier = (d['subscription_tier'] as String? ?? 'free').toLowerCase();
      return AdminShopPlanRow(
        shopId: doc.id,
        shopName: (d['shop_name'] as String? ?? d['name'] as String? ?? doc.id),
        city: (d['city'] as String? ?? ''),
        tier: tier.isEmpty ? 'free' : tier,
        isVerified: (d['verification_status'] as String? ?? '') == 'verified',
        whatsappBalance: balances[doc.id] ?? 0,
      );
    }).toList();
    rows.sort((a, b) => a.shopName.compareTo(b.shopName));
    return rows;
  }

  Future<bool> setShopPlan({
    required String shopId,
    required String tier,
    String reason = '',
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    final normalized = tier.trim().toLowerCase();
    await fs.collection('shops').doc(shopId).set({
      'subscription_tier': normalized,
      'subscription_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AdminAuditService.logAction(
      action: 'shop_plan_changed',
      targetType: 'shop',
      targetId: shopId,
      detail: reason.trim().isEmpty
          ? 'Plan set to $normalized.'
          : 'Plan set to $normalized: ${reason.trim()}',
    );
    await _notifyOwner(
      shopId: shopId,
      title: 'Plan Updated',
      body: 'Your showroom plan is now ${normalized.toUpperCase()}.',
      type: 'subscription_updated',
      route: RouteNames.ownerSubscription,
    );
    return true;
  }

  Future<List<AdminSubscriptionRequest>> getSubscriptionRequests({
    String? status,
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) return [];
    Query<Map<String, dynamic>> query = fs.collection('subscription_requests');
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    final list = snap.docs
        .map((d) => AdminSubscriptionRequest.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  Future<bool> decideSubscriptionRequest({
    required String requestId,
    required String shopId,
    required String tier,
    required bool approve,
    String reason = '',
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    final status = approve ? 'approved' : 'rejected';
    await fs.collection('subscription_requests').doc(requestId).set({
      'status': status,
      if (reason.trim().isNotEmpty) 'decision_reason': reason.trim(),
      'decided_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (approve && shopId.isNotEmpty) {
      await fs.collection('shops').doc(shopId).set({
        'subscription_tier': tier.trim().toLowerCase(),
        'subscription_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await AdminAuditService.logAction(
      action: approve
          ? 'subscription_request_approved'
          : 'subscription_request_rejected',
      targetType: 'subscription_request',
      targetId: requestId,
      decision: status,
      detail: 'Shop $shopId ($tier)${reason.trim().isEmpty ? '' : ': ${reason.trim()}'}',
    );
    if (shopId.isNotEmpty) {
      await _notifyOwner(
        shopId: shopId,
        title: approve ? 'Plan Upgrade Approved' : 'Plan Upgrade Rejected',
        body: approve
            ? 'Your ${tier.toUpperCase()} showroom plan is now active.'
            : (reason.trim().isNotEmpty
                ? reason.trim()
                : 'Your plan upgrade request could not be approved.'),
        type: 'subscription_decision',
        route: RouteNames.ownerSubscription,
      );
    }
    return true;
  }

  Future<List<AdminCreditRequest>> getCreditPurchaseRequests({
    String? status,
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) return [];
    Query<Map<String, dynamic>> query =
        fs.collection('credit_purchase_requests');
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    final list = snap.docs
        .map((d) => AdminCreditRequest.fromMap(d.id, d.data()))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  Future<bool> decideCreditPurchaseRequest({
    required String requestId,
    required String shopId,
    required int packCredits,
    required bool approve,
    String reason = '',
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    final status = approve ? 'approved' : 'rejected';
    await fs.collection('credit_purchase_requests').doc(requestId).set({
      'status': status,
      if (reason.trim().isNotEmpty) 'decision_reason': reason.trim(),
      'decided_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (approve && shopId.isNotEmpty && packCredits > 0) {
      await fs.collection('whatsapp_credits').doc(shopId).set({
        'balance': FieldValue.increment(packCredits),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await AdminAuditService.logAction(
      action: approve
          ? 'whatsapp_credits_request_approved'
          : 'whatsapp_credits_request_rejected',
      targetType: 'credit_purchase_request',
      targetId: requestId,
      decision: status,
      detail:
          'Shop $shopId (+$packCredits credits)${reason.trim().isEmpty ? '' : ': ${reason.trim()}'}',
    );
    if (shopId.isNotEmpty) {
      await _notifyOwner(
        shopId: shopId,
        title: approve
            ? 'WhatsApp Credits Added'
            : 'WhatsApp Credit Request Rejected',
        body: approve
            ? '$packCredits WhatsApp credits have been added to your showroom balance.'
            : (reason.trim().isNotEmpty
                ? reason.trim()
                : 'Your WhatsApp credit request could not be approved.'),
        type: 'whatsapp_credits_decision',
        route: RouteNames.ownerWhatsappCredits,
      );
    }
    return true;
  }

  Future<bool> adjustShopCredits({
    required String shopId,
    required int deltaCredits,
    String reason = '',
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _resolvedFirestore;
    if (fs == null || deltaCredits == 0) return false;
    await fs.collection('whatsapp_credits').doc(shopId).set({
      'balance': FieldValue.increment(deltaCredits),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AdminAuditService.logAction(
      action: 'whatsapp_credits_adjusted',
      targetType: 'shop',
      targetId: shopId,
      detail:
          'Adjusted by ${deltaCredits > 0 ? '+$deltaCredits' : '$deltaCredits'} credits${reason.trim().isEmpty ? '' : ': ${reason.trim()}'}',
    );
    await _notifyOwner(
      shopId: shopId,
      title: 'WhatsApp Credits Updated',
      body: deltaCredits > 0
          ? '$deltaCredits WhatsApp credits were granted to your showroom.'
          : '${deltaCredits.abs()} WhatsApp credits were adjusted from your showroom.',
      type: 'whatsapp_credits_adjusted',
      route: RouteNames.ownerWhatsappCredits,
    );
    return true;
  }

  Future<void> _notifyOwner({
    required String shopId,
    required String title,
    required String body,
    required String type,
    required String route,
  }) async {
    final notifications = _resolvedNotifications;
    if (notifications == null || shopId.isEmpty) return;
    try {
      await notifications.createNotification(
        shopId: shopId,
        title: title,
        body: body,
        type: type,
        targetRoute: route,
      );
    } catch (_) {}
  }
}
