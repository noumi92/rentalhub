import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/sync_engine.dart';
import '../../../../core/data/sync_queue_entry.dart';
import '../../../../core/error/exceptions.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

class BookingRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final NotificationDataSource? _notifications;
  final BlacklistRemoteDataSource? _blacklist;

  /// Phase B (B1/B3): the persisted pending-write store. When set,
  /// a Firestore write that fails (offline) is queued here instead
  /// of living only in memory — the booking survives a restart and
  /// syncs on reconnect. Null in tests, where the in-memory
  /// fallback keeps the old behaviour.
  final OfflineSyncQueue? syncQueue;

  final Map<String, BookingModel> _inMemoryFallback = {};
  static int _idSeq = 0;

  BookingRemoteDataSource(
      {FirebaseFirestore? firestore,
      NotificationDataSource? notifications,
      BlacklistRemoteDataSource? blacklist,
      this.syncQueue})
      : _firestore = firestore,
        _notifications = notifications,
        _blacklist = blacklist;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Phase B (G2): owner notifications are best-effort — a failed
  /// write must never fail the booking it describes.
  Future<void> _notify({
    required String shopId,
    required String title,
    required String body,
    required String type,
    String? bookingId,
  }) async {
    final ds = _notifications;
    if (ds == null) return;
    try {
      await ds.createNotification(
        shopId: shopId,
        title: title,
        body: body,
        type: type,
        bookingId: bookingId,
      );
    } catch (_) {}
  }

  /// Phase B (B4): validate-before-queue. A booking payload with
  /// no id or no parties is rejected loudly, never queued.
  void _validateBookingMap(Map<String, dynamic> map) {
    final id = map['bookingId'] as String?;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Cannot queue a booking with no bookingId.');
    }
    for (final field in ['customerId', 'shopId', 'vehicleId']) {
      final value = map[field] as String?;
      if (value == null || value.isEmpty) {
        throw ArgumentError('Cannot queue a booking with no $field.');
      }
    }
  }

  /// Phase B (B1): a failed Firestore write goes to the persisted
  /// queue instead of dying in memory. No queue wired (tests) → the
  /// old in-memory fallback is all there is. Only the booking id is
  /// validated here: update payloads are partial (`{'fields': …}`),
  /// so the full-map check lives in `createBookingRequest` only.
  Future<void> _queueWrite(
    String kind,
    String bookingId,
    Map<String, dynamic> payload,
  ) async {
    final queue = syncQueue;
    if (queue == null) return;
    if (bookingId.isEmpty) {
      throw ArgumentError('Cannot queue a booking with no bookingId.');
    }
    await queue.enqueue(
      kind: kind,
      entityId: bookingId,
      payload: payload,
    );
  }

  /// Phase B (B3): the engine's handler for a queued booking
  /// create. Merge-set by doc id makes the retry idempotent.
  Future<bool> syncQueuedCreate(
      SyncQueueEntry entry, SyncEngine engine) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      final map = Map<String, dynamic>.from(entry.payload);
      await fs.collection('bookings').doc(entry.entityId).set(
        {
          ...map,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase B (B3): the engine's handler for a queued booking
  /// update (status / proof / verification fields).
  Future<bool> syncQueuedUpdate(
      SyncQueueEntry entry, SyncEngine engine) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      final fields =
          Map<String, dynamic>.from(entry.payload['fields'] as Map? ?? {});
      await fs.collection('bookings').doc(entry.entityId).set(
        {
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase B (B1): bookings that exist only in the queue (created
  /// offline, not yet synced) so reads see them.
  Future<List<BookingModel>> _pendingQueueBookings() async {
    final queue = syncQueue;
    if (queue == null) return [];
    final entries = await queue.pendingEntries();
    final out = <BookingModel>[];
    for (final entry in entries) {
      if (entry.kind == 'booking_create') {
        try {
          out.add(BookingModel.fromMap(
              Map<String, dynamic>.from(entry.payload), entry.entityId));
        } catch (_) {}
      }
    }
    return out;
  }

  /// Phase B (B1): pending status/proof updates for one booking,
  /// applied on top of the stored model so reads show the latest
  /// local state while the server write is still queued.
  Future<BookingModel> _applyPendingUpdates(BookingModel model) async {
    final queue = syncQueue;
    if (queue == null) return model;
    final entries = await queue.entriesForEntity(model.bookingId);
    var map = model.toMap();
    var changed = false;
    for (final entry in entries) {
      if (entry.kind != 'booking_update') continue;
      final fields =
          Map<String, dynamic>.from(entry.payload['fields'] as Map? ?? {});
      map = {...map, ...fields};
      changed = true;
    }
    if (!changed) return model;
    try {
      return BookingModel.fromMap(map, model.bookingId);
    } catch (_) {
      return model;
    }
  }

  /// Phase B (B4): every write carries a server timestamp for
  /// ordering (D7: server timestamp wins for status fields) and
  /// uses merge semantics so a concurrent change to another field
  /// is never clobbered.
  Future<bool> _writeBookingDoc(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    try {
      await fs.collection('bookings').doc(bookingId).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase B (B1): merges queued offline creates into a list
  /// result (deduped by id) and applies queued updates, so lists
  /// show the latest local state while server writes are pending.
  Future<List<BookingModel>> _mergePendingInto(
      List<BookingModel> list) async {
    final pending = await _pendingQueueBookings();
    final byId = {for (final b in list) b.bookingId: b};
    for (final p in pending) {
      byId.putIfAbsent(p.bookingId, () => p);
    }
    final out = <BookingModel>[];
    for (final b in byId.values) {
      out.add(await _applyPendingUpdates(b));
    }
    return out;
  }

  Future<BookingModel> createBookingRequest({
    required String customerId,
    required String shopId,
    required String vehicleId,
    required String packageType,
    required bool isWithDriver,
    required DateTime pickupTime,
    required DateTime returnTime,
    required int totalAmount,
    required int advanceRequired,
    String? vehicleName,
    String? vehiclePlate,
    String? shopName,
    String? shopPhone,
    String? customerName,
    String? customerPhone,
    String? notes,
    String? customerCnic,
    String? guarantorName,
    String? guarantorCnic,
    String? guarantorPhone,
    String tripType = 'in_city',
    int? kmLimit,
  }) async {
    // Phase C (C2): the booking-time blacklist check. The owner
    // walk-in flow already refuses blacklisted CNICs; the customer
    // online flow did not — a blacklisted customer could book online
    // unchecked. The check runs here so every caller is covered, and
    // a missing Firestore connection fails open (the walk-in path
    // behaves the same way when offline).
    final blacklist = _blacklist;
    if (blacklist != null) {
      for (final cnic in [customerCnic, guarantorCnic]) {
        if (cnic != null && cnic.trim().isNotEmpty) {
          if (await blacklist.isCnicBlacklisted(cnic)) {
            throw const ServerException(
              message:
                  'This CNIC is on the shared RentalHub blacklist. Please contact the showroom.',
            );
          }
        }
      }
    }
    // Millisecond ids can collide when two bookings are created back
    // to back, so a per-process counter keeps each id unique.
    final id =
        'RH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-${_idSeq++}';
    final model = BookingModel(
      bookingId: id,
      customerId: customerId,
      shopId: shopId,
      vehicleId: vehicleId,
      packageType: packageType,
      isWithDriver: isWithDriver,
      pickupTime: pickupTime,
      returnTime: returnTime,
      totalAmount: totalAmount,
      advanceRequired: advanceRequired,
      advancePaid: 0,
      remainingBalance: totalAmount,
      status: 'requested',
      vehicleName: vehicleName,
      vehiclePlate: vehiclePlate,
      shopName: shopName,
      shopPhone: shopPhone,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
      customerCnic: customerCnic,
      guarantorName: guarantorName,
      guarantorCnic: guarantorCnic,
      guarantorPhone: guarantorPhone,
      tripType: tripType,
      kmLimit: kmLimit,
    );

    _inMemoryFallback[id] = model;

    // Phase B (B1/B4): merge-set + server timestamps; on failure
    // the booking is queued (persisted) instead of living only in
    // memory — an offline request is never silently lost.
    final written = await _writeBookingDoc(id, {
      ...model.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!written) {
      // Phase B (B4): validate the full map before queueing — a
      // booking with no id or no parties is rejected loudly, never
      // queued.
      _validateBookingMap(model.toMap());
      await _queueWrite('booking_create', id, model.toMap());
    }

    // Phase B (G2): an online request alerts the shop. Walk-in
    // bookings (customerId 'walkin-…') do not — the owner is
    // standing at the counter when those are made.
    if (!customerId.startsWith('walkin-')) {
      await _notify(
        shopId: shopId,
        title: 'New booking request',
        body:
            '${customerName ?? 'A customer'} requested ${vehicleName ?? 'a car'} • $packageType • Rs. $totalAmount',
        type: 'booking_request',
        bookingId: id,
      );
    }

    return model;
  }

  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
    String? rejectionReason,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(
      status: status,
      rejectionReason: rejectionReason,
    );
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    final fields = <String, dynamic>{'status': status};
    if (rejectionReason != null) {
      fields['rejectionReason'] = rejectionReason;
    }
    final written = await _writeBookingDoc(bookingId, fields);
    if (!written) {
      await _queueWrite('booking_update', bookingId, {'fields': fields});
    }
    return model;
  }

  /// Phase B (D3): the owner rejects a payment proof. The booking
  /// goes back to 'approved' with the reason, so the customer can
  /// fix it and upload a new proof.
  Future<BookingEntity> rejectPaymentProof({
    required String bookingId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError('A reason is required to reject a proof.');
    }
    return updateBookingStatus(
      bookingId: bookingId,
      status: 'approved',
      rejectionReason: reason.trim(),
    );
  }

  Future<BookingEntity> updatePaymentProof({
    required String bookingId,
    required String paymentProofUrl,
    required String transactionId,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(
      status: 'payment_submitted',
      paymentProofUrl: paymentProofUrl.isEmpty ? null : paymentProofUrl,
      transactionId: transactionId,
      clearRejectionReason: true,
    );
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    // Phase B (B3): when the proof image is still queued (empty
    // URL), the field is omitted entirely — a queued upload entry
    // writes the real URL when it lands, and a queued update here
    // must never clobber it back to empty.
    final fields = <String, dynamic>{
      'status': 'payment_submitted',
      'transactionId': transactionId,
      'rejectionReason': null,
    };
    if (paymentProofUrl.isNotEmpty) {
      fields['paymentProofUrl'] = paymentProofUrl;
    }
    final written = await _writeBookingDoc(bookingId, fields);
    if (!written) {
      await _queueWrite('booking_update', bookingId, {'fields': fields});
    }
    // Phase B (G2): the owner needs to know a proof is waiting.
    await _notify(
      shopId: existing.shopId,
      title: 'Payment proof submitted',
      body:
          '${existing.customerName ?? 'A customer'} uploaded payment proof for #$bookingId • TID $transactionId',
      type: 'payment_proof',
      bookingId: bookingId,
    );
    return model;
  }

  Future<BookingEntity> verifyPayment({
    required String bookingId,
    required int advanceAmount,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(
      status: 'paid',
      advancePaid: advanceAmount,
    );
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    final fields = <String, dynamic>{
      'status': 'paid',
      'advancePaid': advanceAmount,
      'remainingBalance': updated.remainingBalance,
    };
    final written = await _writeBookingDoc(bookingId, fields);
    if (!written) {
      await _queueWrite('booking_update', bookingId, {'fields': fields});
    }
    return model;
  }

  Future<BookingEntity?> getBookingById(String bookingId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final doc = await fs.collection('bookings').doc(bookingId).get();
        if (doc.exists && doc.data() != null) {
          final model = BookingModel.fromMap(doc.data()!, doc.id);
          _inMemoryFallback[bookingId] = model;
          return _applyPendingUpdates(model);
        }
      } catch (_) {}
    }
    // Phase B (B1): a booking that only exists in the queue
    // (created offline, not yet synced) is still readable.
    final queue = syncQueue;
    if (queue != null) {
      final entry = await queue.entryFor('booking_create', bookingId);
      if (entry != null) {
        try {
          final model = BookingModel.fromMap(
              Map<String, dynamic>.from(entry.payload), bookingId);
          return _applyPendingUpdates(model);
        } catch (_) {}
      }
    }
    final cached = _inMemoryFallback[bookingId];
    if (cached == null) return null;
    return _applyPendingUpdates(cached);
  }

  Stream<BookingEntity?> streamBooking(String bookingId) {
    final fs = _resolvedFirestore;
    if (fs != null) {
      return fs.collection('bookings').doc(bookingId).snapshots().map((doc) {
        if (doc.exists && doc.data() != null) {
          return BookingModel.fromMap(doc.data()!, doc.id);
        }
        return _inMemoryFallback[bookingId];
      });
    }
    return Stream.value(_inMemoryFallback[bookingId]);
  }

  Future<List<BookingEntity>> getCustomerBookings(String customerId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('bookings')
            .where('customerId', isEqualTo: customerId)
            .get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
          return _mergePendingInto(list);
        }
      } catch (_) {}
    }
    final list = _inMemoryFallback.values
        .where((b) => b.customerId == customerId)
        .toList();
    return _mergePendingInto(list);
  }

  Future<List<BookingEntity>> getShopBookings(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('bookings')
            .where('shopId', isEqualTo: shopId)
            .get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
          return _mergePendingInto(list);
        }
      } catch (_) {}
    }
    final list =
        _inMemoryFallback.values.where((b) => b.shopId == shopId).toList();
    return _mergePendingInto(list);
  }

  /// Phase B (B3): all bookings of one vehicle, for the availability
  /// calendar. Firestore first, in-memory fallback when offline.
  /// Cancelled and rejected bookings do not block the calendar.
  Future<List<BookingEntity>> getVehicleBookings(String vehicleId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('bookings')
            .where('vehicleId', isEqualTo: vehicleId)
            .get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
          return _mergePendingInto(list);
        }
      } catch (_) {}
    }
    final list = _inMemoryFallback.values
        .where((b) =>
            b.vehicleId == vehicleId &&
            b.status != 'cancelled' &&
            b.status != 'rejected')
        .toList();
    return _mergePendingInto(list);
  }
}
