import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_audit_service.dart';

/// Item 6 — the admin side of customer KYC review.
///
/// A customer who submits their own documents in the app writes
/// `kyc_documents/{uid}` with `status: 'submitted'` (see
/// KycRemoteDataSource.uploadCnicAndLicense). Until this data source
/// existed nothing ever wrote 'verified' or 'rejected' for those
/// records: the owner-side Approve/Reject on the owner customer
/// detail screen is for owner-added customers only and does not touch
/// `kyc_documents`, and the admin Approvals section is for SHOP
/// applications. This is the missing half — the queue of pending
/// submissions plus the decision that closes one.
///
/// Decisions write back to the `kyc_documents` doc and are
/// audit-logged; write methods return whether the cloud write
/// actually happened, so a view never claims a decision that only
/// lived on the device (same contract as AdminShopsDataSource).
class AdminKycDataSource {
  final FirebaseFirestore? _firestore;

  AdminKycDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Pending customer KYC submissions (status 'submitted'), newest
  /// first by the submission timestamp. The customer's display name
  /// comes from their `customers/{uid}` record; a submission whose
  /// customer record is missing still lists, with an empty name.
  Future<List<KycReviewSubmission>> getPendingKycSubmissions() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('kyc_documents')
          .where('status', isEqualTo: 'submitted')
          .limit(100)
          .get();
      final out = <KycReviewSubmission>[];
      for (final d in snap.docs) {
        var name = '';
        try {
          final customerDoc =
              await firestore.collection('customers').doc(d.id).get();
          name = (customerDoc.data()?['name'] as String?) ?? '';
        } catch (_) {}
        out.add(KycReviewSubmission.fromMap(d.id, d.data(), name: name));
      }
      // Newest first. The query has no orderBy (a where + orderBy on
      // the server timestamp would need a composite index), so the
      // sort happens here; a record with no timestamp sorts last.
      return sortNewestFirst(out);
    } catch (_) {
      return [];
    }
  }

  /// Newest first by submission time; a record with no timestamp
  /// sorts last. Static so the ordering is unit-testable without a
  /// fake Firestore.
  static List<KycReviewSubmission> sortNewestFirst(
      List<KycReviewSubmission> submissions) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final sorted = List<KycReviewSubmission>.of(submissions);
    sorted.sort((a, b) =>
        (b.submittedAt ?? epoch).compareTo(a.submittedAt ?? epoch));
    return sorted;
  }

  /// One submission by customer id, or null when there is none.
  Future<KycReviewSubmission?> getKycSubmission(String customerId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore
          .collection('kyc_documents')
          .doc(customerId)
          .get();
      final data = doc.data();
      if (data == null) return null;
      var name = '';
      try {
        final customerDoc =
            await firestore.collection('customers').doc(customerId).get();
        name = (customerDoc.data()?['name'] as String?) ?? '';
      } catch (_) {}
      return KycReviewSubmission.fromMap(doc.id, data, name: name);
    } catch (_) {
      return null;
    }
  }

  /// Decide a submission: 'verified' or 'rejected'. A rejection
  /// needs a reason — the customer sees it in their KYC banner.
  /// Returns false for an invalid decision, a reason-less rejection,
  /// or a failed cloud write; the reason is validated here so a
  /// caller cannot bypass the requirement by calling the data source
  /// directly.
  Future<bool> decideKyc({
    required String customerId,
    required String decision,
    String reason = '',
  }) async {
    if (decision != 'verified' && decision != 'rejected') return false;
    final trimmedReason = reason.trim();
    if (decision == 'rejected' && trimmedReason.isEmpty) return false;
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('kyc_documents').doc(customerId).update({
        'status': decision,
        if (decision == 'rejected') 'rejection_reason': trimmedReason,
        'reviewed_at': FieldValue.serverTimestamp(),
      });
      // Best-effort mirror: the customer KYC banner reads the reason
      // off `customers/{uid}.rejectionReason` (CustomerDocumentsView),
      // not off the KYC record. A missing customer record must not
      // fail a decision that already landed, so this write never
      // throws — merge-set so it creates the record if needed, and a
      // verification clears any earlier rejection reason.
      try {
        await firestore.collection('customers').doc(customerId).set({
          if (decision == 'rejected') 'rejectionReason': trimmedReason,
          if (decision == 'verified')
            'rejectionReason': FieldValue.delete(),
        }, SetOptions(merge: true));
      } catch (_) {}
      await AdminAuditService.logAction(
        action: decision == 'verified'
            ? 'customer_kyc_verified'
            : 'customer_kyc_rejected',
        targetType: 'customer',
        targetId: customerId,
        detail: trimmedReason,
        decision: decision,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// One customer KYC submission awaiting (or having received) a
/// decision. The image fields are cPanel `kyc` keys, not URLs — the
/// review detail resolves them to signed media URLs, the same way
/// the owner KYC uploader and the payment-proof view do.
class KycReviewSubmission {
  const KycReviewSubmission({
    required this.customerId,
    required this.customerName,
    required this.cnicNumber,
    required this.cnicFrontKey,
    required this.cnicBackKey,
    required this.licenseKey,
    required this.licenseBackKey,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.submittedAt,
  });

  final String customerId;
  final String customerName;
  final String cnicNumber;
  final String cnicFrontKey;
  final String cnicBackKey;
  final String licenseKey;
  final String licenseBackKey;
  final String licenseNumber;
  final String licenseExpiry;

  /// The submission time (`updatedAt` server timestamp, written when
  /// the customer submitted). Null when the record has no timestamp.
  final DateTime? submittedAt;

  factory KycReviewSubmission.fromMap(
    String customerId,
    Map<String, dynamic> data, {
    String name = '',
  }) {
    final submitted = data['submittedAt'] ?? data['updatedAt'];
    DateTime? submittedAt;
    if (submitted is Timestamp) {
      submittedAt = submitted.toDate();
    } else if (submitted is String) {
      submittedAt = DateTime.tryParse(submitted);
    }
    return KycReviewSubmission(
      customerId: customerId,
      customerName: name,
      cnicNumber: data['cnicNumber'] as String? ?? '',
      cnicFrontKey: data['cnicFrontKey'] as String? ?? '',
      cnicBackKey: data['cnicBackKey'] as String? ?? '',
      licenseKey: data['licenseKey'] as String? ?? '',
      licenseBackKey: data['licenseBackKey'] as String? ?? '',
      licenseNumber: data['licenseNumber'] as String? ?? '',
      licenseExpiry: data['licenseExpiry'] as String? ?? '',
      submittedAt: submittedAt,
    );
  }
}
