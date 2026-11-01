import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_model.dart';

class BookingRemoteDataSource {
  final FirebaseFirestore? _firestore;
  final Map<String, BookingModel> _inMemoryFallback = {};

  BookingRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
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
  }) async {
    final id = 'RH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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

    return model;
  }

  Future<BookingEntity> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final existing = await getBookingById(bookingId);
    if (existing == null) {
      throw Exception('Booking not found: $bookingId');
    }
    final updated = existing.copyWith(status: status);
    final model = BookingModel.fromEntity(updated);
    _inMemoryFallback[bookingId] = model;

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('bookings').doc(bookingId).update({'status': status});
      } catch (_) {}
    }
    return model;
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
        });
      } catch (_) {}
    }
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
}
