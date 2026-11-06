import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';
import '../../../blacklist/domain/entities/blacklist_entity.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/data/datasources/review_remote_data_source.dart';
import '../../../customer/data/models/customer_model.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../services/admin_audit_service.dart';
import '../../domain/trust_score_calculator.dart';

/// Phase C — the people side of the admin panel: customers, the
/// platform blacklist, and the trust score.
///
/// The trust score shown here is the C3 formula (see
/// trust_score_calculator.dart), computed live from the customer's
/// KYC state, completed trips, owner ratings, deposit release times
/// (on-time proxy) and adverse events. It is computed, not stored —
/// the `trust_score` field on the users doc is the older stored value
/// and is shown alongside for comparison, not as the source of truth.
class AdminPeopleDataSource {
  final FirebaseFirestore? _firestore;

  AdminPeopleDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<List<CustomerModel>> getCustomers() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('customers')
          .orderBy('name')
          .limit(200)
          .get();
      return snap.docs
          .map((d) => CustomerModel.fromMap(d.data(), d.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CustomerDetail?> getCustomerDetail(String customerId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final customerDoc =
          await firestore.collection('customers').doc(customerId).get();
      final customerData = customerDoc.data();
      if (customerData == null) return null;
      final customer = CustomerModel.fromMap(customerData, customerDoc.id);

      final userDoc =
          await firestore.collection('users').doc(customerId).get();
      final userData = userDoc.data();
      final storedTrustScore =
          (userData?['trust_score'] as num?)?.toDouble();
      final isBlacklisted = userData?['is_blacklisted'] as bool? ?? false;

      final kycDoc = await firestore
          .collection('kyc_documents')
          .doc(customerId)
          .get();
      final kycData = kycDoc.data();
      final kycStatus = kycData?['status'] as String? ?? 'missing';
      final kycCnic = kycData?['cnicNumber'] as String?;

      final bookings = await BookingRemoteDataSource(firestore: firestore)
          .getCustomerBookings(customerId);
      final completed =
          bookings.where((b) => b.status == 'completed').toList();

      final reviews = await ReviewRemoteDataSource(firestore: firestore)
          .getCustomerReviews(customerId, onlyOwnerRated: true);
      final meanRating = _meanOwnerRating(reviews);

      int onTime = 0;
      int late = 0;
      int deducted = 0;
      for (final booking in completed.take(20)) {
        final depositDoc = await firestore
            .collection('security_deposits')
            .doc(booking.bookingId)
            .get();
        final deposit = depositDoc.data();
        if (deposit == null) continue;
        if (deposit['status'] == 'deducted') deducted++;
        final released = deposit['releasedAt'];
        DateTime? releasedAt;
        if (released is Timestamp) {
          releasedAt = released.toDate();
        } else if (released is String) {
          releasedAt = DateTime.tryParse(released);
        }
        if (releasedAt == null) continue;
        if (!releasedAt.isAfter(booking.returnTime)) {
          onTime++;
        } else {
          late++;
        }
      }

      final disputesSnap = await firestore
          .collection('disputes')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'resolved')
          .get();
      var adverseDisputes = 0;
      for (final d in disputesSnap.docs) {
        final decision = d.data()['decision'] as String?;
        if (decision == 'full_to_owner' || decision == 'partial') {
          adverseDisputes++;
        }
      }

      final breakdown = TrustScoreCalculator.calculate(
        kycStatus: kycStatus,
        completedTrips: completed.length,
        meanOwnerRating: meanRating,
        onTimeReturns: onTime,
        lateReturns: late,
        adverseEvents: deducted + adverseDisputes,
      );

      BlacklistEntity? blacklistRecord;
      final cnic = customer.cnic ?? kycCnic;
      if (cnic != null && cnic.isNotEmpty) {
        blacklistRecord = await BlacklistRemoteDataSource(
                firestore: firestore)
            .getBlacklistRecordByCnic(cnic);
      }

      final notesSnap = await firestore
          .collection('customers')
          .doc(customerId)
          .collection('admin_notes')
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();
      final notes = notesSnap.docs
          .map((d) => AdminNote.fromMap(d.id, d.data()))
          .toList();

      return CustomerDetail(
        customer: customer,
        storedTrustScore: storedTrustScore,
        isBlacklisted: isBlacklisted,
        kycStatus: kycStatus,
        bookings: bookings,
        completedTrips: completed.length,
        meanOwnerRating: meanRating,
        trustBreakdown: breakdown,
        blacklistRecord: blacklistRecord,
        notes: notes,
      );
    } catch (_) {
      return null;
    }
  }

  double? _meanOwnerRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return null;
    var sum = 0.0;
    var count = 0;
    for (final r in reviews) {
      for (final key in ['punctualityRating', 'careRating', 'behaviorRating']) {
        final v = (r[key] as num?)?.toDouble();
        if (v != null) {
          sum += v;
          count++;
        }
      }
    }
    if (count == 0) return null;
    return sum / count;
  }

  /// A watchlist flag on the customer record (admin eyes only).
  Future<bool> setCustomerWatchlisted({
    required String customerId,
    required bool watchlisted,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('customers').doc(customerId).update({
        'watchlisted': watchlisted,
      });
      await AdminAuditService.logAction(
        action: watchlisted
            ? 'customer_watchlisted'
            : 'customer_unwatchlisted',
        targetType: 'customer',
        targetId: customerId,
        detail: watchlisted
            ? 'Customer added to the watchlist.'
            : 'Customer removed from the watchlist.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Report a customer to the shared blacklist (C2). The report goes
  /// through the shared blacklist data source so the booking-time
  /// check sees it immediately.
  Future<bool> reportCustomerToBlacklist({
    required String customerId,
    required String cnic,
    required String phone,
    required String reasonCategory,
    required String description,
    required String reportedByShopId,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await BlacklistRemoteDataSource(firestore: firestore)
          .reportCustomerToBlacklist(
        cnicNumber: cnic,
        phoneNumber: phone,
        reasonCategory: reasonCategory,
        description: description,
        reportedByShopId: reportedByShopId,
      );
      await AdminAuditService.logAction(
        action: 'customer_blacklisted',
        targetType: 'customer',
        targetId: customerId,
        detail: '$reasonCategory: $description',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addCustomerNote({
    required String customerId,
    required String text,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore
          .collection('customers')
          .doc(customerId)
          .collection('admin_notes')
          .add({
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Every blacklist record, active and reverted, newest first.
  /// The shared blacklist data source falls back to its in-memory
  /// records when Firestore is unreachable, so this does not bail
  /// out on a null Firestore — only the appeal-state reads need one.
  Future<List<AdminBlacklistRecord>> getBlacklistRecords() async {
    final firestore = _resolvedFirestore;
    try {
      final records = await BlacklistRemoteDataSource(firestore: firestore)
          .getAllRecords();
      final out = <AdminBlacklistRecord>[];
      for (final r in records) {
        var appealStatus = 'none';
        var appealReason = '';
        if (firestore != null) {
          try {
            final doc = await firestore
                .collection('blacklist')
                .doc(r.blacklistId)
                .get();
            appealStatus =
                doc.data()?['appeal_status'] as String? ?? 'none';
            appealReason = doc.data()?['appeal_reason'] as String? ?? '';
          } catch (_) {}
        }
        out.add(AdminBlacklistRecord(
          entity: r,
          appealStatus: appealStatus,
          appealReason: appealReason,
        ));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Decide an appeal: 'keep' leaves the flag in place (appeal
  /// denied), 'remove' lifts it via the tribunal revert (reason
  /// mandatory, logged). Returns false when the write failed.
  Future<bool> decideAppeal({
    required String blacklistId,
    required String decision,
    required String reason,
    required String adminUid,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      if (decision == 'remove') {
        await BlacklistRemoteDataSource(firestore: firestore)
            .revertBlacklistRecord(
          blacklistId: blacklistId,
          adminUid: adminUid,
          justification: reason,
        );
      }
      await firestore.collection('blacklist').doc(blacklistId).update({
        'appeal_status': decision == 'keep' ? 'kept' : 'removed',
        'appeal_reason': reason,
        'appeal_decided_at': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: decision == 'keep'
            ? 'blacklist_appeal_kept'
            : 'blacklist_appeal_removed',
        targetType: 'blacklist',
        targetId: blacklistId,
        detail: reason,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Everything the customer detail screen shows, assembled from the
/// collections that actually hold it.
class CustomerDetail {
  const CustomerDetail({
    required this.customer,
    required this.storedTrustScore,
    required this.isBlacklisted,
    required this.kycStatus,
    required this.bookings,
    required this.completedTrips,
    required this.meanOwnerRating,
    required this.trustBreakdown,
    required this.blacklistRecord,
    required this.notes,
  });

  final CustomerEntity customer;
  final double? storedTrustScore;
  final bool isBlacklisted;
  final String kycStatus;
  final List<BookingEntity> bookings;
  final int completedTrips;
  final double? meanOwnerRating;
  final TrustScoreBreakdown trustBreakdown;
  final BlacklistEntity? blacklistRecord;
  final List<AdminNote> notes;
}

/// An admin's private note on a customer.
class AdminNote {
  const AdminNote({
    required this.id,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String text;
  final DateTime? createdAt;

  factory AdminNote.fromMap(String id, Map<String, dynamic> data) {
    final created = data['created_at'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return AdminNote(
      id: id,
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

/// A blacklist record with its appeal state (C2). The appeal fields
/// live on the blacklist document; the shared entity does not carry
/// them, so this admin-side wrapper holds them.
class AdminBlacklistRecord {
  const AdminBlacklistRecord({
    required this.entity,
    required this.appealStatus,
    required this.appealReason,
  });

  final BlacklistEntity entity;
  final String appealStatus;
  final String appealReason;
}
