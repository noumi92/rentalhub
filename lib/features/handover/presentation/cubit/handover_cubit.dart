import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/sync_engine.dart';
import '../../../../core/data/sync_queue_entry.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../finance/data/datasources/security_deposit_data_source.dart';
import '../../../finance/data/services/booking_ledger_service.dart';
import '../../data/datasources/handover_local_data_source.dart';
import '../../data/datasources/pdf_contract_generator.dart';
import '../../domain/entities/handover_entity.dart';

abstract class HandoverState extends Equatable {
  const HandoverState();
  @override
  List<Object?> get props => [];
}

class HandoverInitial extends HandoverState {
  const HandoverInitial();
}

class HandoverSavedOffline extends HandoverState {
  final HandoverEntity handover;
  const HandoverSavedOffline(this.handover);
  @override
  List<Object?> get props => [handover];
}

class HandoverSynced extends HandoverState {
  final HandoverEntity handover;
  final int syncedCount;
  const HandoverSynced({required this.handover, required this.syncedCount});
  @override
  List<Object?> get props => [handover, syncedCount];
}

/// Phase B (E2/E3): handover with a real A4 PDF and a real sync.
/// The PDF is generated on the phone, saved offline with the
/// handover, and — when online — uploaded to the cPanel `agreements`
/// folder and recorded in Firestore `agreements/{bookingId}` so the
/// verification page can find it. A failed upload never fails the
/// handover itself: the record stays pending and syncs later.
class HandoverCubit extends Cubit<HandoverState> {
  final HandoverLocalDataSource localDataSource;
  final CPanelStorageClient? storageClient;
  final SecurityDepositDataSource? depositDataSource;
  final FirebaseFirestore? _firestore;

  /// Financial audit (2026-11-20): posts handover cash to the
  /// ledger and applies a collected balance to the booking.
  /// Both optional — null keeps the old behaviour (handover
  /// recorded, cash unledgered). Best-effort by design: a ledger
  /// or booking failure must never fail the handover itself.
  final BookingLedgerService? ledgerService;
  final BookingRemoteDataSource? bookingDataSource;

  HandoverCubit({
    required this.localDataSource,
    this.storageClient,
    this.depositDataSource,
    FirebaseFirestore? firestore,
    this.ledgerService,
    this.bookingDataSource,
  })  : _firestore = firestore,
        super(const HandoverInitial());

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<HandoverEntity> completeHandoverOfflineFirst({
    required String bookingId,
    String shopId = '',
    String shopName = '',
    required String customerName,
    String customerId = '',
    String customerPhone = '',
    String cnicNumber = '',
    required String vehicleDetails,
    String packageType = '24h',
    bool isWithDriver = false,
    DateTime? pickupTime,
    DateTime? returnTime,
    int totalAmount = 0,
    int advancePaid = 0,
    int securityDeposit = 0,
    int? extraHourPkr,
    int cashReceivedAtHandover = 0,
    // Audit 2026-11-15 PW-16: the balance due at handover and how
    // it was collected — recorded on the entity and synced with it
    // (see [_syncOne]), never a side merge from the view.
    int? balanceDuePkr,
    String? balancePaymentMethod,
    // Financial audit (2026-11-20): whether the balance / deposit
    // were actually received (the wizard's Received toggles).
    // Null = unknown (legacy callers pass neither): the balance is
    // inferred from the method ('not_yet' = not collected, any
    // real method = collected) and the deposit is inferred from
    // the receipt timestamp, or assumed collected when no method
    // was picked at all (the legacy single-view has no toggle and
    // always collected the deposit with the handover). The wizard
    // finalize should pass the toggles explicitly — see the audit
    // report — because a toggled-off deposit keeps a stale
    // [depositReceivedAt] from an earlier toggle-on.
    bool? balanceReceived,
    bool? depositReceived,
    String? vehicleId,
    required int initialOdometer,
    required String fuelLevel,
    List<String> damageNotes = const [],
    // Audit item 4 (O19): exterior photos + handover checklist,
    // carried onto the stored record and the Firestore handover doc.
    String? photoFrontUrl,
    String? photoBackUrl,
    String? photoLeftUrl,
    String? photoRightUrl,
    List<String> documentsGiven = const [],
    List<String> accessories = const [],
    bool keysHandedOver = false,
    // Item 9 (O26–O30): the wizard's new fields — carried onto the
    // stored record and the Firestore handover/agreement docs.
    bool faceCheckConfirmed = false,
    DateTime? faceCheckedAt,
    String? depositPaymentMethod,
    DateTime? depositReceivedAt,
    String? receiptId,
    bool? acWorking,
    bool? lightsWorking,
    String? photoInteriorUrl,
    String? photoDashboardUrl,
    Map<String, String> photoTakenAt = const {},
    List<HandoverDamagePin> damagePins = const [],
    DateTime? tripStartAt,
    DateTime? wizardCompletedAt,
    String? customerSignatureSource,
    String? ownerSignatureSource,
    // Audit item 14 (O23): real vehicle detail for the PDF.
    String? vehiclePlate,
    String? vehicleColour,
    String? vehicleFuel,
    // Item 10 (O46–O48): guarantor identity for the PDF detail
    // block — read from the booking by the caller.
    String? guarantorName,
    String? guarantorCnic,
    String? guarantorRelation,
    Uint8List? customerSignaturePng,
    Uint8List? ownerSignaturePng,
    Uint8List? guarantorSignaturePng,
    // Kept for the older call sites (tests); the real pads now pass
    // PNG bytes instead.
    String customerSignatureSvg = '',
    String ownerSignatureSvg = '',
    bool isOnline = false,
  }) async {
    final pdfBytes = await PdfContractGenerator.generateA4Agreement(
      agreementId: bookingId,
      shopName: shopName,
      customerName: customerName,
      cnicNumber: cnicNumber,
      customerPhone: customerPhone,
      vehicleDetails: vehicleDetails,
      packageType: packageType,
      isWithDriver: isWithDriver,
      pickupTime: pickupTime ?? DateTime.now(),
      returnTime: returnTime ?? DateTime.now().add(const Duration(days: 1)),
      handedOverAt: tripStartAt ?? DateTime.now(),
      extraHourPkr: extraHourPkr,
      cashReceivedAtHandover: cashReceivedAtHandover,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      securityDeposit: securityDeposit,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      customerSignaturePng: customerSignaturePng,
      ownerSignaturePng: ownerSignaturePng,
      guarantorSignaturePng: guarantorSignaturePng,
      vehiclePlate: vehiclePlate,
      vehicleColour: vehicleColour,
      vehicleFuel: vehicleFuel,
      guarantorName: guarantorName,
      guarantorCnic: guarantorCnic,
      guarantorRelation: guarantorRelation,
      // Item 10: the true photo count — never the spec's "8".
      // Item 9 (O29): the wizard's interior + dashboard slots count.
      handoverPhotoCount: [
        photoFrontUrl,
        photoBackUrl,
        photoLeftUrl,
        photoRightUrl,
        photoInteriorUrl,
        photoDashboardUrl,
      ].where((url) => url != null && url.isNotEmpty).length,
    );

    var entity = HandoverEntity(
      bookingId: bookingId,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      photoFrontUrl: photoFrontUrl,
      photoBackUrl: photoBackUrl,
      photoLeftUrl: photoLeftUrl,
      photoRightUrl: photoRightUrl,
      photoInteriorUrl: photoInteriorUrl,
      photoDashboardUrl: photoDashboardUrl,
      photoTakenAt: photoTakenAt,
      damagePins: damagePins,
      documentsGiven: documentsGiven,
      accessories: accessories,
      keysHandedOver: keysHandedOver,
      faceCheckConfirmed: faceCheckConfirmed,
      faceCheckedAt: faceCheckedAt,
      depositPaymentMethod: depositPaymentMethod,
      depositReceivedAt: depositReceivedAt,
      receiptId: receiptId,
      acWorking: acWorking,
      lightsWorking: lightsWorking,
      tripStartAt: tripStartAt ?? DateTime.now(),
      wizardCompletedAt: wizardCompletedAt ?? DateTime.now(),
      customerSignatureSource: customerSignatureSource,
      ownerSignatureSource: ownerSignatureSource,
      customerSignatureSvg: customerSignatureSvg,
      ownerSignatureSvg: ownerSignatureSvg,
      customerSignatureB64: customerSignaturePng != null
          ? base64Encode(customerSignaturePng)
          : null,
      ownerSignatureB64:
          ownerSignaturePng != null ? base64Encode(ownerSignaturePng) : null,
      agreementPdfB64: base64Encode(pdfBytes),
      shopId: shopId,
      shopName: shopName,
      customerId: customerId,
      customerName: customerName,
      cnicNumber: cnicNumber,
      vehicleDetails: vehicleDetails,
      totalAmount: totalAmount,
      balanceDuePkr: balanceDuePkr,
      balancePaymentMethod: balancePaymentMethod,
      // Financial audit (2026-11-20): the effective received
      // flags (see the parameter docs above). Stored on the
      // record so the return flow can tell a held deposit from
      // one that was never taken.
      balanceReceived: _effectiveBalanceReceived(
        balanceDuePkr: balanceDuePkr,
        balancePaymentMethod: balancePaymentMethod,
        balanceReceived: balanceReceived,
      ),
    );

    await localDataSource.saveHandoverOffline(entity);

    // Financial audit (2026-11-20): was the deposit actually
    // received? Before this the record below was written whenever
    // the vehicle charged a deposit — even with the Received
    // toggle OFF — so the deposits summary showed money the shop
    // never took.
    final depositCollected = depositReceived ??
        (depositReceivedAt != null || depositPaymentMethod == null);
    // Phase B (F2): the deposit is held from the moment the car
    // leaves. Best-effort — a failed record must never fail the
    // handover itself; the return flow backfills it if needed.
    if (depositCollected && securityDeposit > 0 && depositDataSource != null) {
      try {
        await depositDataSource!.collect(
          bookingId: bookingId,
          customerId: customerId,
          shopId: shopId,
          amount: securityDeposit,
          collectedAt: pickupTime ?? DateTime.now(),
        );
      } catch (_) {}
    }

    // Financial audit (2026-11-20): the handover cash, posted to
    // the ledger exactly once (deterministic ids) and applied to
    // the booking — before this a balance collected here never
    // reduced the booking's remaining balance, so the dues view
    // kept showing it as owed and the return flow could collect
    // the same balance a second time. All best-effort: a ledger
    // failure never fails the handover.
    await _postHandoverCash(
      bookingId: bookingId,
      shopId: shopId,
      customerId: customerId,
      vehicleId: vehicleId,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      pickupTime: pickupTime,
      returnTime: returnTime,
      packageType: packageType,
      balanceDuePkr: balanceDuePkr,
      balancePaymentMethod: balancePaymentMethod,
      balanceCollected: entity.balanceReceived ?? false,
      securityDeposit: securityDeposit,
      depositCollected: depositCollected,
      depositPaymentMethod: depositPaymentMethod,
    );

    if (isOnline) {
      final url = await _syncOne(entity);
      if (url != null) {
        entity = entity.copyWith(agreementPdfUrl: url, isSynced: true);
        emit(HandoverSynced(handover: entity, syncedCount: 1));
      } else {
        emit(HandoverSavedOffline(entity));
      }
    } else {
      emit(HandoverSavedOffline(entity));
    }
    return entity;
  }

  /// Financial audit (2026-11-20): the effective balance-received
  /// flag for the record. Null when nothing was due (moot);
  /// otherwise the explicit toggle when given, else the method —
  /// 'not_yet' (or no method) means the balance stays owed.
  static bool? _effectiveBalanceReceived({
    required int? balanceDuePkr,
    required String? balancePaymentMethod,
    required bool? balanceReceived,
  }) {
    if (balanceDuePkr == null || balanceDuePkr <= 0) return null;
    if (balanceReceived != null) return balanceReceived;
    return balancePaymentMethod != null &&
        balancePaymentMethod != 'not_yet';
  }

  Future<void> _postHandoverCash({
    required String bookingId,
    required String shopId,
    required String customerId,
    required String? vehicleId,
    required int totalAmount,
    required int advancePaid,
    required DateTime? pickupTime,
    required DateTime? returnTime,
    required String packageType,
    required int? balanceDuePkr,
    required String? balancePaymentMethod,
    required bool balanceCollected,
    required int securityDeposit,
    required bool depositCollected,
    required String? depositPaymentMethod,
  }) async {
    final ledger = ledgerService;
    final remainingBefore = (totalAmount - advancePaid).clamp(0, 1 << 30);
    final collectedBalance =
        balanceCollected && balanceDuePkr != null && balanceDuePkr > 0
            ? balanceDuePkr.clamp(0, remainingBefore)
            : 0;
    final booking = BookingEntity(
      bookingId: bookingId,
      customerId: customerId,
      shopId: shopId,
      vehicleId: vehicleId ?? '',
      packageType: packageType,
      pickupTime: pickupTime ?? DateTime.now(),
      returnTime: returnTime ?? DateTime.now().add(const Duration(days: 1)),
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      remainingBalance: remainingBefore,
    );
    if (collectedBalance > 0) {
      if (ledger != null) {
        try {
          await ledger.postOnce(
            booking: booking,
            event: 'balance',
            kind: 'income',
            category: 'rent',
            amount: collectedBalance,
            paymentMethod: balancePaymentMethod,
            note: 'Balance collected at handover for $bookingId',
          );
        } catch (_) {}
      }
      try {
        await bookingDataSource?.recordBalanceCollected(
          bookingId: bookingId,
          amount: collectedBalance,
        );
      } catch (_) {}
    }
    if (ledger != null && depositCollected && securityDeposit > 0) {
      try {
        await ledger.postOnce(
          booking: booking,
          event: 'deposit',
          kind: 'income',
          category: 'deposit',
          amount: securityDeposit,
          paymentMethod: depositPaymentMethod,
          note: 'Security collected for $bookingId',
        );
      } catch (_) {}
    }
  }

  /// Phase B (B4): the agreement PDF hash, recorded in Firestore
  /// so the integrity check can verify the uploaded file matches
  /// what the phone generated.
  static String agreementPdfHash(List<int> pdfBytes) =>
      sha256.convert(pdfBytes).toString();

  /// Phase B (B3): the sync engine's handler for a queued
  /// handover entry. The payload is the handover JSON saved by
  /// [HandoverLocalDataSource]; [_syncOne] does the upload + the
  /// Firestore writes and marks the entry synced.
  Future<bool> syncQueuedEntry(
      SyncQueueEntry entry, SyncEngine engine) async {
    try {
      final map = Map<String, dynamic>.from(entry.payload);
      final entity = HandoverEntity(
        bookingId: map['booking_id'] as String? ?? entry.entityId,
        initialOdometer: (map['odometer'] as num?)?.toInt() ?? 0,
        fuelLevel: map['fuel_level'] as String? ?? '',
        damageNotes: List<String>.from(map['damage_notes'] ?? []),
        customerSignatureSvg: map['customer_signature'] as String? ?? '',
        ownerSignatureSvg: map['owner_signature'] as String? ?? '',
        customerSignatureB64: map['customer_signature_b64'] as String?,
        ownerSignatureB64: map['owner_signature_b64'] as String?,
        agreementPdfB64: map['agreement_pdf_b64'] as String?,
        shopId: map['shop_id'] as String?,
        shopName: map['shop_name'] as String?,
        customerName: map['customer_name'] as String?,
        cnicNumber: map['cnic'] as String?,
        vehicleDetails: map['vehicle_details'] as String?,
        totalAmount: (map['total_amount'] as num?)?.toInt(),
        balanceDuePkr: (map['balance_due_pkr'] as num?)?.toInt(),
        balancePaymentMethod: map['balance_payment_method'] as String?,
        balanceReceived: map['balance_received'] as bool?,
        photoFrontUrl: map['photo_front_url'] as String?,
        photoBackUrl: map['photo_back_url'] as String?,
        photoLeftUrl: map['photo_left_url'] as String?,
        photoRightUrl: map['photo_right_url'] as String?,
        photoInteriorUrl: map['photo_interior_url'] as String?,
        photoDashboardUrl: map['photo_dashboard_url'] as String?,
        photoTakenAt: Map<String, String>.from(
            (map['photo_taken_at'] as Map? ?? {}).map(
                (k, v) => MapEntry(k.toString(), v.toString()))),
        damagePins: (map['damage_pins'] as List? ?? [])
            .map((p) => HandoverDamagePin.fromJson(
                Map<String, dynamic>.from(p as Map)))
            .toList(),
        documentsGiven: List<String>.from(map['documents_given'] ?? []),
        accessories: List<String>.from(map['accessories'] ?? []),
        keysHandedOver: map['keys_handed_over'] == true,
        faceCheckConfirmed: map['face_check_confirmed'] == true,
        faceCheckedAt: _queuedDate(map['face_checked_at']),
        depositPaymentMethod: map['deposit_payment_method'] as String?,
        depositReceivedAt: _queuedDate(map['deposit_received_at']),
        receiptId: map['receipt_id'] as String?,
        acWorking: map['ac_working'] as bool?,
        lightsWorking: map['lights_working'] as bool?,
        tripStartAt: _queuedDate(map['trip_start_at']),
        wizardCompletedAt: _queuedDate(map['wizard_completed_at']),
        customerSignatureSource: map['customer_signature_source'] as String?,
        ownerSignatureSource: map['owner_signature_source'] as String?,
        agreementPdfUrl: map['agreement_pdf_url'] as String?,
        isSynced: false,
      );
      return await _syncOne(entity) != null;
    } catch (_) {
      return false;
    }
  }

  static DateTime? _queuedDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Future<int> syncPendingHandovers() async {
    final pending = await localDataSource.getPendingSyncHandovers();
    var synced = 0;
    for (final item in pending) {
      final url = await _syncOne(item);
      if (url == null) continue;
      synced++;
      emit(
        HandoverSynced(
          handover: item.copyWith(agreementPdfUrl: url, isSynced: true),
          syncedCount: synced,
        ),
      );
    }
    return synced;
  }

  /// Uploads one pending agreement and records it in Firestore.
  /// Returns the signed PDF URL, or null when it could not sync
  /// (offline, upload failed) — the record stays pending.
  Future<String?> _syncOne(HandoverEntity item) async {
    // No storage client (tests): keep the previous local-only sync.
    if (storageClient == null) {
      await localDataSource.markSynced(
          item.bookingId, item.agreementPdfUrl ?? '');
      return item.agreementPdfUrl ?? '';
    }
    final pdfB64 = item.agreementPdfB64;
    if (pdfB64 == null) return null;
    try {
      final pdfBytes = base64Decode(pdfB64);
      final pdfHash = agreementPdfHash(pdfBytes);
      final tmp = File(
          '${Directory.systemTemp.path}/agreement-${item.bookingId}.pdf');
      await tmp.writeAsBytes(pdfBytes);
      final userUid =
          (item.shopId != null && item.shopId!.isNotEmpty)
              ? item.shopId!
              : item.bookingId;
      final key = await storageClient!.uploadFile(
        file: tmp,
        userUid: userUid,
        folder: 'agreements',
      );
      final url = storageClient!.getSignedMediaUrl(key, userUid);

      final fs = _resolvedFirestore;
      if (fs != null) {
        // Phase B (B4): merge semantics + server timestamps (D7:
        // server timestamp wins for status fields) so a retry never
        // clobbers a concurrent change, and ordering never depends
        // on the phone's clock.
        await fs.collection('agreements').doc(item.bookingId).set({
          'agreementId': item.bookingId,
          'bookingId': item.bookingId,
          'shopId': item.shopId ?? '',
          'shopName': item.shopName ?? '',
          'customerId': item.customerId ?? '',
          'customerName': item.customerName ?? '',
          'cnicNumber': item.cnicNumber ?? '',
          'vehicleDetails': item.vehicleDetails ?? '',
          'totalAmount': item.totalAmount ?? 0,
          // Audit 2026-11-15 PW-16: the handover balance, recorded
          // with the agreement (merge — a retry never clobbers).
          // Absent entirely when unknown (older queued records),
          // never a fabricated 0.
          if (item.balanceDuePkr != null) ...{
            'balanceDueAtHandover': item.balanceDuePkr,
            'balancePaymentMethod': item.balancePaymentMethod,
            if (item.balanceReceived != null)
              'balanceReceived': item.balanceReceived,
          },
          // Item 9 (O27/O30): the receipt + the trip start, so the
          // agreement doc can show when the trip actually started.
          if (item.receiptId != null) 'receiptId': item.receiptId,
          if (item.tripStartAt != null)
            'tripStartAt': Timestamp.fromDate(item.tripStartAt!),
          'agreementPdfUrl': url,
          'agreementPdfSha256': pdfHash,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // E3: the handover record itself — odometer and fuel at pickup —
        // so the customer's active-trip view can show the real handover
        // values instead of the agreement doc, which does not carry them.
        await fs.collection('handovers').doc(item.bookingId).set({
          'bookingId': item.bookingId,
          'shopId': item.shopId ?? '',
          'shopName': item.shopName ?? '',
          'customerId': item.customerId ?? '',
          'customerName': item.customerName ?? '',
          'initialOdometer': item.initialOdometer,
          'fuelLevel': item.fuelLevel,
          'damageNotes': item.damageNotes,
          'photoFrontUrl': item.photoFrontUrl,
          'photoBackUrl': item.photoBackUrl,
          'photoLeftUrl': item.photoLeftUrl,
          'photoRightUrl': item.photoRightUrl,
          'photoInteriorUrl': item.photoInteriorUrl,
          'photoDashboardUrl': item.photoDashboardUrl,
          'photoTakenAt': item.photoTakenAt,
          'damagePins':
              item.damagePins.map((p) => p.toJson()).toList(),
          'documentsGiven': item.documentsGiven,
          'accessories': item.accessories,
          'keysHandedOver': item.keysHandedOver,
          // Audit 2026-11-15 PW-16: same balance record on the
          // handover doc itself (absent when unknown).
          if (item.balanceDuePkr != null) ...{
            'balanceDueAtHandover': item.balanceDuePkr,
            'balancePaymentMethod': item.balancePaymentMethod,
            if (item.balanceReceived != null)
              'balanceReceived': item.balanceReceived,
          },
          // Item 9 (O26–O30): the wizard fields. Face check is a
          // confirmed flag + timestamp only — never a match score.
          'faceCheckConfirmed': item.faceCheckConfirmed,
          if (item.faceCheckedAt != null)
            'faceCheckedAt': Timestamp.fromDate(item.faceCheckedAt!),
          if (item.depositPaymentMethod != null)
            'depositPaymentMethod': item.depositPaymentMethod,
          if (item.depositReceivedAt != null)
            'depositReceivedAt':
                Timestamp.fromDate(item.depositReceivedAt!),
          if (item.receiptId != null) 'receiptId': item.receiptId,
          if (item.acWorking != null) 'acWorking': item.acWorking,
          if (item.lightsWorking != null)
            'lightsWorking': item.lightsWorking,
          if (item.tripStartAt != null)
            'tripStartAt': Timestamp.fromDate(item.tripStartAt!),
          if (item.wizardCompletedAt != null)
            'wizardCompletedAt':
                Timestamp.fromDate(item.wizardCompletedAt!),
          if (item.customerSignatureSource != null)
            'customerSignatureSource': item.customerSignatureSource,
          if (item.ownerSignatureSource != null)
            'ownerSignatureSource': item.ownerSignatureSource,
          'agreementPdfUrl': url,
          'agreementPdfSha256': pdfHash,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await localDataSource.markSynced(item.bookingId, url);
      return url;
    } catch (_) {
      return null;
    }
  }
}
