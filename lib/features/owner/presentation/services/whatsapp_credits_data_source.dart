import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/shop_id_resolution.dart';
import 'whatsapp_credits_models.dart';

export 'whatsapp_credits_models.dart';

/// WhatsApp credits data (deck Step 7, W1–W6) — gated on D2
/// (Meta/WhatsApp). The balance starts at 0 and is never seeded with
/// the deck's example 84; dispatch rows come only from the
/// `whatsapp_dispatch_logs` collection, which has no rows until a real
/// dispatch exists. Purchases are manual bank transfers
/// (`credit_purchase_requests`, admin verifies) — never Google Play
/// until D1/D2 are done.
class WhatsappCreditsDataSource {
  FirebaseFirestore? get _resolvedFirestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<int> getBalance(String shopId) async {
    // Shop-id linking (2026-11-15): the credits document is keyed
    // by the shop doc id; the bare UID read always missed. The admin
    // balance read resolves the same way.
    final fs = _resolvedFirestore;
    if (fs == null) return 0;
    try {
      final doc = await fs
          .collection('whatsapp_credits')
          .doc(await canonicalShopId(fs, shopId))
          .get();
      return (doc.data()?['balance'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<WhatsappAutoSettings> getAutoSettings(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const WhatsappAutoSettings();
    try {
      final doc = await fs
          .collection('whatsapp_settings')
          .doc(await canonicalShopId(fs, shopId))
          .get();
      final data = doc.data();
      if (data != null) {
        final nested = data['autoMessages'];
        if (nested is Map<String, dynamic>) {
          return WhatsappAutoSettings.fromMap(nested);
        }
        return WhatsappAutoSettings.fromMap(data);
      }
      final shop = await fs
          .collection('shops')
          .doc(await canonicalShopId(fs, shopId))
          .get();
      final auto = shop.data()?['whatsapp_settings'];
      if (auto is Map<String, dynamic>) {
        final nested = auto['autoMessages'];
        if (nested is Map<String, dynamic>) {
          return WhatsappAutoSettings.fromMap(nested);
        }
      }
    } catch (_) {}
    return const WhatsappAutoSettings();
  }

  Future<void> saveAutoToggle(
      String shopId, String key, bool value) async {
    final fs = _resolvedFirestore;
    if (fs == null) throw StateError('Firestore is not available.');
    final canonical = await canonicalShopId(fs, shopId);
    await fs.collection('whatsapp_settings').doc(canonical).set({
      'shopId': canonical,
      'autoMessages': {key: value},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> submitCreditPurchaseRequest({
    required String shopId,
    required int pack,
    required int amount,
    required String transactionId,
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) throw StateError('Firestore is not available.');
    final canonical = await canonicalShopId(fs, shopId);
    await fs.collection('credit_purchase_requests').add({
      'shopId': canonical,
      'pack': pack,
      'amount': amount,
      'transactionId': transactionId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CreditPurchaseRequest>> getPurchaseRequests(
      String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const [];
    try {
      final ids = await candidateShopIds(fs, shopId);
      final snap = await fs
          .collection('credit_purchase_requests')
          .where('shopId', whereIn: ids)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => CreditPurchaseRequest.fromMap(d.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<WhatsappDispatchLog>> getDispatchLogs(
    String shopId, {
    String category = 'all',
  }) async {
    final fs = _resolvedFirestore;
    if (fs == null) return const [];
    try {
      final ids = await candidateShopIds(fs, shopId);
      var query = fs
          .collection('whatsapp_dispatch_logs')
          .where('shopId', whereIn: ids);
      if (category != 'all') {
        query = query.where('category', isEqualTo: category);
      }
      final snap = await query.orderBy('sentAt', descending: true).get();
      return snap.docs
          .map((d) => WhatsappDispatchLog.fromMap(d.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Auto-messages skipped for zero balance, from the
  /// `whatsapp_skipped_messages` collection. Nothing writes there
  /// before D2 (no auto-send exists yet), so this is 0 until the
  /// WhatsApp sender records a real skip — the W6 amber banner only
  /// appears when this is > 0 AND the balance is 0.
  Future<int> getSkippedCount(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs == null) return 0;
    try {
      final ids = await candidateShopIds(fs, shopId);
      final snap = await fs
          .collection('whatsapp_skipped_messages')
          .where('shopId', whereIn: ids)
          .where('reason', isEqualTo: 'zero_balance')
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }
}
