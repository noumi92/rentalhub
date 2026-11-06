import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

class BookingRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final NotificationDataSource? _notifications;
  final BlacklistRemoteDataSource? _blacklist;
  final Map<String, BookingModel> _inMemoryFallback = {};
  static int _idSeq = 0;

  BookingRemoteDataSource(
      {FirebaseFirestore? firestore,
      NotificationDataSource? notifications,
      BlacklistRemoteDataSource? blacklist})
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

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('bookings').doc(id).set(model.toMap());
      } catch (_) {
        // Fallback silently kept in memory for offline/test environments
      }
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

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final update = <String, dynamic>{'status': status};
        if (rejectionReason != null) {
          update['rejectionReason'] = rejectionReason;
        }
        await fs.collection('bookings').doc(bookingId).update(update);
      } catch (_) {}
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
      paymentProofUrl: paymentProofUrl,
      transactionId: transactionId,
      clearRejectionReason: true,
    );
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('bookings').doc(bookingId).update({
          'status': 'payment_submitted',
          'paymentProofUrl': paymentProofUrl,
          'transactionId': transactionId,
          'rejectionReason': null,
        });
      } catch (_) {}
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

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('bookings').doc(bookingId).update({
          'status': 'paid',
          'advancePaid': advanceAmount,
          'remainingBalance': updated.remainingBalance,
        });
      } catch (_) {}
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
          return model;
        }
      } catch (_) {}
    }
    return _inMemoryFallback[bookingId];
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
          return snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryFallback.values
        .where((b) => b.customerId == customerId)
        .toList();
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
          return snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryFallback.values
        .where((b) => b.shopId == shopId)
        .toList();
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
          return snap.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryFallback.values
        .where((b) =>
            b.vehicleId == vehicleId &&
            b.status != 'cancelled' &&
            b.status != 'rejected')
        .toList();
  }
}
