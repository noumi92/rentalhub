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
import '../../../finance/data/datasources/security_deposit_data_source.dart';
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

  HandoverCubit({
    required this.localDataSource,
    this.storageClient,
    this.depositDataSource,
    FirebaseFirestore? firestore,
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
    required int initialOdometer,
    required String fuelLevel,
    List<String> damageNotes = const [],
    Uint8List? customerSignaturePng,
    Uint8List? ownerSignaturePng,
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
      totalAmount: totalAmount,
      advancePaid: advancePaid,
      securityDeposit: securityDeposit,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      customerSignaturePng: customerSignaturePng,
      ownerSignaturePng: ownerSignaturePng,
    );

    var entity = HandoverEntity(
      bookingId: bookingId,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
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
      customerName: customerName,
      cnicNumber: cnicNumber,
      vehicleDetails: vehicleDetails,
      totalAmount: totalAmount,
    );

    await localDataSource.saveHandoverOffline(entity);

    // Phase B (F2): the deposit is held from the moment the car
    // leaves. Best-effort — a failed record must never fail the
    // handover itself; the return flow backfills it if needed.
    if (securityDeposit > 0 && depositDataSource != null) {
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
        agreementPdfUrl: map['agreement_pdf_url'] as String?,
        isSynced: false,
      );
      return await _syncOne(entity) != null;
    } catch (_) {
      return false;
    }
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
          'customerName': item.customerName ?? '',
          'cnicNumber': item.cnicNumber ?? '',
          'vehicleDetails': item.vehicleDetails ?? '',
          'totalAmount': item.totalAmount ?? 0,
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
          'customerName': item.customerName ?? '',
          'initialOdometer': item.initialOdometer,
          'fuelLevel': item.fuelLevel,
          'damageNotes': item.damageNotes,
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
