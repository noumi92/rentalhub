import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/utils/shop_id_resolution.dart';

import '../../domain/entities/security_deposit_entity.dart';
import '../models/security_deposit_model.dart';

/// Phase B (F2): the `security_deposits` collection, Firestore-first
/// with an in-memory fallback — the same pattern as the other
/// datasources. One document per booking (doc id = booking id).
class SecurityDepositDataSource {
  final FirebaseFirestore? _firestore;
  final OfflineSyncQueue? syncQueue;
  final Map<String, SecurityDepositModel> _inMemory = {};

  SecurityDepositDataSource({FirebaseFirestore? firestore, this.syncQueue})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Phase B (B1/B3): a failed Firestore write is queued (persisted)
  /// instead of dying in memory. Returns true when confirmed.
  Future<bool> _writeDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      await fs.collection(collection).doc(docId).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _queueDoc(
    String collection,
    String docId,
    Map<String, dynamic> fields,
  ) async {
    final queue = syncQueue;
    if (queue == null) return;
    await queue.enqueue(
      kind: 'firestore_set',
      entityId: docId,
      payload: {
        'collection': collection,
        'docId': docId,
        'fields': fields,
      },
    );
  }

  Future<SecurityDepositEntity?> getByBookingId(String bookingId) async {
    if (_inMemory.containsKey(bookingId)) return _inMemory[bookingId];
    final fs = _resolvedFirestore;
    if (fs == null) return null;
    try {
      final doc =
          await fs.collection('security_deposits').doc(bookingId).get();
      if (!doc.exists || doc.data() == null) return null;
      final model = SecurityDepositModel.fromMap(doc.data()!);
      _inMemory[bookingId] = model;
      return model;
    } catch (_) {
      return null;
    }
  }

  /// Phase B (H4): every deposit the shop holds, for the finance
  /// summary — collected, released and deducted.
  Future<List<SecurityDepositEntity>> getShopDeposits(String shopId) async {
    // Shop-id linking (2026-11-15): deposits are collected under the
    // booking's shop id (the canonical doc id) while this read used
    // to query the bare UID — the finance summary missed every
    // deposit. Match both forms.
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('security_deposits')
            .where('shopId', whereIn: ids)
            .get();
        for (final d in snap.docs) {
          final model = SecurityDepositModel.fromMap(d.data());
          _inMemory[model.bookingId] = model;
        }
      } catch (_) {}
    }
    final mine = _inMemory.values.where((d) => ids.contains(d.shopId)).toList()
      ..sort((a, b) =>
          (b.collectedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                  a.collectedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return mine;
  }

  /// Records the deposit as held when the car leaves (handover).
  /// Idempotent: collecting twice for the same booking keeps the
  /// first record.
  Future<SecurityDepositEntity> collect({
    required String bookingId,
    required String customerId,
    required String shopId,
    required int amount,
    DateTime? collectedAt,
  }) async {
    final existing = await getByBookingId(bookingId);
    if (existing != null) return existing;
    final canonical = await canonicalShopId(_resolvedFirestore, shopId);
    final model = SecurityDepositModel(
      depositId: bookingId,
      bookingId: bookingId,
      customerId: customerId,
      shopId: canonical,
      amount: amount,
      status: 'collected',
      collectedAt: collectedAt ?? DateTime.now(),
    );
    _inMemory[bookingId] = model;
    final written = await _writeDoc('security_deposits', bookingId, model.toMap());
    if (!written) await _queueDoc('security_deposits', bookingId, model.toMap());
    return model;
  }

  /// Worker B (cancel releases the deposit): releases a held
  /// deposit IN FULL when its booking is cancelled — a cancelled
  /// booking has no km / fuel / damage to deduct, so [netRefund]
  /// is the whole [amount] and [deductedAmount] is 0. The advance
  /// is untouched (it stays with the showroom).
  ///
  /// Idempotent, same pattern as [collect]: no record → null
  /// (nothing held, nothing to release); an already-released or
  /// deducted record is returned unchanged, so a double-cancel
  /// can never release twice. Deliberately NOT [settle] — that
  /// needs the full return breakdown and throws when no record
  /// exists.
  Future<SecurityDepositEntity?> releaseOnCancel({
    required String bookingId,
  }) async {
    final existing = await getByBookingId(bookingId);
    if (existing == null) return null;
    if (existing.status != 'collected') return existing;
    final released = existing.copyWith(
      status: 'released',
      releasedAt: DateTime.now(),
      deductedAmount: 0,
      netRefund: existing.amount,
      amountOwed: 0,
      releaseReason: 'cancel',
    );
    final model = SecurityDepositModel.fromEntity(released);
    _inMemory[bookingId] = model;
    final written =
        await _writeDoc('security_deposits', bookingId, model.toMap());
    if (!written) {
      await _queueDoc('security_deposits', bookingId, model.toMap());
    }
    return released;
  }

  /// Settles the deposit at return. Nothing deducted → 'released'
  /// with a releasedAt timestamp; anything deducted → 'deducted'
  /// with a deductedAt timestamp and the full breakdown.
  ///
  /// Item 2: [deductedAmount] is capped at the amount actually
  /// held — deductions above the deposit are not "deducted from"
  /// money the shop never took. The excess is stored as
  /// [SecurityDepositEntity.amountOwed] (the settlement's
  /// amountOwed), so the finance summary's deducted row and the
  /// customer wallet never show a deduction larger than the held
  /// deposit — including the Rs 0-deposit case, where every rupee
  /// of deductions is owed, not deducted.
  Future<SecurityDepositEntity> settle({
    required String bookingId,
    required int totalKmDriven,
    required int excessKm,
    required int excessKmCharge,
    required int fuelDeficit,
    required int damageCharge,
    required int overtimeFee,
    required int deductedAmount,
    required int netRefund,
    List<String> returnDamageNotes = const [],
  }) async {
    final existing = await getByBookingId(bookingId);
    if (existing == null) {
      throw StateError('No deposit recorded for booking $bookingId');
    }
    final now = DateTime.now();
    final cappedDeducted = deductedAmount.clamp(0, existing.amount);
    final settled = existing.copyWith(
      status: deductedAmount > 0 ? 'deducted' : 'released',
      releasedAt: deductedAmount > 0 ? null : now,
      deductedAt: deductedAmount > 0 ? now : null,
      totalKmDriven: totalKmDriven,
      excessKm: excessKm,
      excessKmCharge: excessKmCharge,
      fuelDeficit: fuelDeficit,
      damageCharge: damageCharge,
      overtimeFee: overtimeFee,
      deductedAmount: cappedDeducted,
      netRefund: netRefund,
      amountOwed: deductedAmount - cappedDeducted,
      returnDamageNotes: returnDamageNotes,
    );
    final model = SecurityDepositModel.fromEntity(settled);
    _inMemory[bookingId] = model;
    final written = await _writeDoc('security_deposits', bookingId, model.toMap());
    if (!written) await _queueDoc('security_deposits', bookingId, model.toMap());
    return settled;
  }
}
