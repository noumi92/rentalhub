import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/sync_engine.dart';
import '../../../../core/data/sync_queue_entry.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../../utils/unverified_shop_gate.dart';
import '../models/booking_model.dart';

class BookingRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final NotificationDataSource? _notifications;
  final BlacklistRemoteDataSource? _blacklist;

  /// Customer rework (Worker E): the unverified-shop gate. Null in
  /// tests and legacy callers — the review screen is the primary
  /// gate and this is the backstop for callers that bypass it.
  final UnverifiedShopBookingGate? unverifiedShopGate;

  /// Phase B (B1/B3): the persisted pending-write store. When set,
  /// a Firestore write that fails (offline) is queued here instead
  /// of living only in memory — the booking survives a restart and
  /// syncs on reconnect. Null in tests, where the in-memory
  /// fallback keeps the old behaviour.
  final OfflineSyncQueue? syncQueue;

  final Map<String, BookingModel> _inMemoryFallback = {};
  static int _idSeq = 0;

  /// Live booking updates (Item 2): every create / status / payment
  /// change notifies this broadcast feed, so the in-memory fallback
  /// branches of the streams below re-emit instead of freezing at
  /// their first value. The Firestore branches are already live via
  /// snapshots; this feed is what makes submit-then-see-it work
  /// offline and in tests, where there is no Firestore app. Writes
  /// still go through the sync queue exactly as before — this only
  /// announces that the local state changed.
  final StreamController<void> _bookingChanges =
      StreamController<void>.broadcast();

  /// The change feed itself, for callers that want a refresh
  /// trigger without a bookings payload.
  Stream<void> get bookingChanges => _bookingChanges.stream;

  void _notifyBookingChanged() {
    if (!_bookingChanges.isClosed) _bookingChanges.add(null);
  }

  /// A fallback stream that yields the current local read now and
  /// re-yields it on every [_notifyBookingChanged]. Built with
  /// `yield*` (not `await for`): cancelling the subscription must
  /// unwind the generator, and an `await for` over the broadcast
  /// change feed never completes its cancel — a widget test that
  /// cancels on dispose hangs on it.
  Stream<T> _liveFallback<T>(T Function() read) async* {
    yield read();
    yield* _bookingChanges.stream.map((_) => read());
  }

  BookingRemoteDataSource(
      {FirebaseFirestore? firestore,
      NotificationDataSource? notifications,
      BlacklistRemoteDataSource? blacklist,
      this.unverifiedShopGate,
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

  /// Shop-id mismatch (2026-11-15, rulebook D12): the shop DOCUMENT
  /// id a new booking for this shop must carry. The walk-in flow
  /// resolves the signed-in owner's bare UID through this before
  /// writing; the customer flow already writes the document id.
  Future<String> canonicalShopIdFor(String shopId) =>
      canonicalShopId(_resolvedFirestore, shopId);

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
      // The queued create just landed: live listeners re-read.
      _notifyBookingChanged();
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
      // The queued update just landed: live listeners re-read.
      _notifyBookingChanged();
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
    String? guarantorRelation,
    String? origin,
    String tripType = 'in_city',
    int? kmLimit,
    String? fixedRouteId,
    String? fixedRouteSummary,
    String? outCityMode,
    int? outCityPerKmPkr,
    double? depositAmountPkr,
    double? discountAmountPkr,
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
    // Customer rework (Worker E): backstop for callers that bypass
    // the review screen's gate. Walk-in bookings (the owner at the
    // counter) are exempt — the setting governs customer bookings.
    // A missing gate or a failed lookup fails open, like the
    // blacklist check above.
    // Booking source: explicit when the caller knows it (walk-in
    // passes 'walk_in', the online review flow 'online'); otherwise
    // derived from the customerId the same way fromMap backfills
    // older docs, so a direct caller can never file a booking with
    // no origin. Resolved FIRST: the walk-in exemption below and the
    // notification rule both key off it, not off the customerId
    // prefix — a walk-in for a REGISTERED customer carries a real
    // customerId, not a 'walkin-…' one.
    final resolvedOrigin = origin ??
        (customerId.startsWith('walkin-') ? 'walk_in' : 'online');
    final gate = unverifiedShopGate;
    // Admin-integration audit (2026-11-10): a suspended shop takes
    // no bookings at all — online or walk-in. Suspension is a
    // platform sanction, not the unverified-booking setting, so the
    // walk-in exemption does not apply here.
    if (gate != null && await gate.isShopSuspended(shopId: shopId)) {
      throw const ServerException(
        message:
            'This shop is currently suspended by the platform. Bookings are disabled.',
      );
    }
    if (gate != null && resolvedOrigin != 'walk_in') {
      if (!await gate.isBookingAllowed(shopId: shopId)) {
        throw const ServerException(
          message:
              'Bookings from unverified shops are currently disabled by the platform.',
        );
      }
    }
    // Booking source: explicit when the caller knows it (walk-in
    // passes 'walk_in', the online review flow 'online'); otherwise
    // derived from the customerId the same way fromMap backfills
    // older docs, so a direct caller can never file a booking with
    // no origin.
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
      guarantorRelation: guarantorRelation,
      origin: resolvedOrigin,
      tripType: tripType,
      kmLimit: kmLimit,
      fixedRouteId: fixedRouteId,
      fixedRouteSummary: fixedRouteSummary,
      outCityMode: outCityMode,
      outCityPerKmPkr: outCityPerKmPkr,
      depositAmountPkr: depositAmountPkr,
      discountAmountPkr: discountAmountPkr,
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
    // bookings do not — the owner is standing at the counter when
    // those are made (keyed off origin, not the customerId prefix,
    // so a walk-in for a registered customer stays silent too).
    if (resolvedOrigin != 'walk_in') {
      await _notify(
        shopId: shopId,
        title: 'New booking request',
        body:
            '${customerName ?? 'A customer'} requested ${vehicleName ?? 'a car'} • $packageType • Rs. ${formatRs(totalAmount)}',
        type: 'booking_request',
        bookingId: id,
      );
    }

    // Live updates (Item 2): the booking is in the local store
    // now, so every subscribed list re-reads — the customer sees
    // it in Bookings / Home / Wallet and the owner in triage and
    // on the dashboard without navigating away and back.
    _notifyBookingChanged();
    return model;
  }

  /// O18: approving with an assigned account also carries
  /// [selectedPaymentAccount] (the account number the customer pays
  /// into) and [paymentDeadline] (now + 30 minutes, display-only —
  /// nothing auto-cancels on it). Both ride the same `fields` map
  /// as the status, so the offline queue replays them together
  /// (syncQueuedUpdate merge-sets `fields`) and reads see them via
  /// _applyPendingUpdates.
  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
    String? rejectionReason,
    String? selectedPaymentAccount,
    DateTime? paymentDeadline,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(
      status: status,
      rejectionReason: rejectionReason,
      selectedPaymentAccount: selectedPaymentAccount,
      paymentDeadline: paymentDeadline,
    );
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    final fields = <String, dynamic>{'status': status};
    if (rejectionReason != null) {
      fields['rejectionReason'] = rejectionReason;
    }
    if (selectedPaymentAccount != null) {
      fields['selectedPaymentAccount'] = selectedPaymentAccount;
    }
    if (paymentDeadline != null) {
      fields['paymentDeadline'] = paymentDeadline.toIso8601String();
    }
    final written = await _writeBookingDoc(bookingId, fields);
    if (!written) {
      await _queueWrite('booking_update', bookingId, {'fields': fields});
    }
    // Live updates (Item 2): an owner approve / reject (or any
    // status change) reaches the customer's lists immediately.
    _notifyBookingChanged();
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
    final proofSubmittedAt = DateTime.now();
    final updated = existing.copyWith(
      status: 'payment_submitted',
      paymentProofUrl: paymentProofUrl.isEmpty ? null : paymentProofUrl,
      transactionId: transactionId,
      proofSubmittedAt: proofSubmittedAt,
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
      'proofSubmittedAt': proofSubmittedAt.toIso8601String(),
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
    _notifyBookingChanged();
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
    _notifyBookingChanged();
    return model;
  }

  /// Audit §5 item 1 (O16/O17): a walk-in advance that does not cover
  /// the required advance yet. The booking is `approved` — not `paid`
  /// — with the received amount recorded, so the remaining balance
  /// stays collectable. A full advance goes through [verifyPayment]
  /// instead; this method never marks a booking paid on its own
  /// unless the received amount covers the required advance.
  Future<BookingEntity> recordAdvancePayment({
    required String bookingId,
    required int advanceAmount,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final received = advanceAmount.clamp(0, existing.totalAmount);
    final updated = existing.copyWith(
      status: received >= existing.advanceRequired ? 'paid' : 'approved',
      advancePaid: received,
    );
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    final fields = <String, dynamic>{
      'status': updated.status,
      'advancePaid': received,
      'remainingBalance': updated.remainingBalance,
    };
    final written = await _writeBookingDoc(bookingId, fields);
    if (!written) {
      await _queueWrite('booking_update', bookingId, {'fields': fields});
    }
    _notifyBookingChanged();
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
          return await _applyPendingUpdates(model);
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
          return await _applyPendingUpdates(model);
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
    return _liveFallback(() => _inMemoryFallback[bookingId]);
  }

  /// Phase C (C3): the live bookings of one shop, for the Requests
  /// tab badge — same source as the dashboard KPI
  /// (`getShopBookings`, waiting = 'requested' or
  /// 'payment_submitted'). Firestore snapshots when available; the
  /// in-memory fallback list when offline or in tests (no Firebase
  /// app), so the badge hides instead of throwing.
  ///
  /// Shop-id mismatch (2026-11-15, rulebook D12): the owner signs in
  /// with the bare UID while customer bookings carry the shop
  /// DOCUMENT id (`shop_<uid>`), so the query matches every
  /// candidate id — the same resolution the fleet layer already
  /// uses. Async generator: the candidates resolve before the
  /// snapshots subscription starts.
  Stream<List<BookingEntity>> streamShopBookings(String shopId) async* {
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      yield* fs
          .collection('bookings')
          .where('shopId', whereIn: ids)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList());
      return;
    }
    yield* _liveFallback(() => _inMemoryFallback.values
        .where((b) => ids.contains(b.shopId))
        .toList());
  }

  /// CU-M11: the live bookings of one customer, for the Bookings tab
  /// badge — same pattern as [streamShopBookings]: Firestore
  /// snapshots when available; the in-memory fallback list when
  /// offline or in tests (no Firebase app), so the badge hides
  /// instead of throwing.
  Stream<List<BookingEntity>> streamCustomerBookings(String customerId) {
    final fs = _resolvedFirestore;
    if (fs != null) {
      return fs
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList());
    }
    return _liveFallback(() => _inMemoryFallback.values
        .where((b) => b.customerId == customerId)
        .toList());
  }

  /// Live bookings of one vehicle, for the per-vehicle calendar and
  /// the booking picker's blocked days — same pattern as
  /// [streamShopBookings]: Firestore snapshots when available, the
  /// live in-memory fallback otherwise.
  Stream<List<BookingEntity>> streamVehicleBookings(String vehicleId) {
    final fs = _resolvedFirestore;
    if (fs != null) {
      return fs
          .collection('bookings')
          .where('vehicleId', isEqualTo: vehicleId)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList());
    }
    return _liveFallback(() => _inMemoryFallback.values
        .where((b) => b.vehicleId == vehicleId)
        .toList());
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
          return await _mergePendingInto(list);
        }
      } catch (_) {}
    }
    final list = _inMemoryFallback.values
        .where((b) => b.customerId == customerId)
        .toList();
    return _mergePendingInto(list);
  }

  Future<List<BookingEntity>> getShopBookings(String shopId) async {
    // Shop-id mismatch (2026-11-15, rulebook D12): match every
    // candidate id, like [streamShopBookings] — customer bookings
    // carry the shop document id, walk-ins the bare UID.
    final ids = await candidateShopIds(_resolvedFirestore, shopId);
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('bookings')
            .where('shopId', whereIn: ids)
            .get();
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
          return await _mergePendingInto(list);
        }
      } catch (_) {}
    }
    final list =
        _inMemoryFallback.values.where((b) => ids.contains(b.shopId)).toList();
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
          return await _mergePendingInto(list);
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
