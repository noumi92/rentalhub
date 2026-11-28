import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/routing/route_names.dart';
import '../../../notifications/data/datasources/notification_data_source.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_session.dart';
import '../../domain/admin_permissions.dart';

/// Item 6 — the admin side of customer KYC review.
///
/// A customer who submits their own documents in the app writes
/// `kyc_documents/{uid}` with `status: 'submitted'` — or
/// 'resubmitted' when a verified record is updated (see
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

  /// Pending customer KYC submissions (status 'submitted' or
  /// 'resubmitted' — a verified customer's updated submission, or a
  /// changed CNIC, waiting for re-review), newest first by the
  /// submission timestamp. The customer's display name comes from
  /// their `customers/{uid}` record; a submission whose customer
  /// record is missing still lists, with an empty name.
  /// Phase 4 (4.3) — client-side sort over the loaded queue (the
  /// queue is client-side: [getPendingKycSubmissions] caps at
  /// 100).
  static List<KycReviewSubmission> sortKycSubmissions(
      List<KycReviewSubmission> submissions, String sort) {
    final list = List<KycReviewSubmission>.of(submissions);
    DateTime at(KycReviewSubmission s) =>
        s.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (sort) {
      case 'dateOldest':
        list.sort((a, b) => at(a).compareTo(at(b)));
      case 'nameAsc':
        list.sort((a, b) => a.customerName.compareTo(b.customerName));
      case 'nameDesc':
        list.sort((a, b) => b.customerName.compareTo(a.customerName));
      default:
        list.sort((a, b) => at(b).compareTo(at(a)));
    }
    return list;
  }

  Future<List<KycReviewSubmission>> getPendingKycSubmissions() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('kyc_documents')
          .where('status', whereIn: const ['submitted', 'resubmitted'])
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

  /// Phase 3 (3.4) — how many submissions are waiting for a
  /// decision in total, so the queue can say "Showing first N of
  /// M" at its 100 cap.
  Future<int> countPendingKyc() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return (await getPendingKycSubmissions()).length;
    }
    final count = await firestore
        .collection('kyc_documents')
        .where('status', whereIn: const ['submitted', 'resubmitted'])
        .count()
        .get();
    return count.count ?? 0;
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
  ///
  /// Phase 1 (1.7) — F-C1: super admin + operations only
  /// ([AdminPermission.decideKyc]), the same backstop every sibling
  /// decision method has ([AdminShopsDataSource.decideShopApplication],
  /// [AdminPlatformDataSource.decideDispute]). The caller's role is
  /// passed by the view when it already resolved it, otherwise
  /// resolved from the session here; an unresolvable role refuses
  /// the write (fail closed).
  Future<bool> decideKyc({
    required String customerId,
    required String decision,
    String reason = '',
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.decideKyc,
        adminRole: adminRole)) {
      return false;
    }
    if (decision != 'verified' && decision != 'rejected') return false;
    final trimmedReason = reason.trim();
    if (decision == 'rejected' && trimmedReason.isEmpty) return false;
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final currentDoc = await firestore
          .collection('kyc_documents')
          .doc(customerId)
          .get();
      final currentData = currentDoc.data();
      if (currentData == null) return false;
      final currentStatus =
          (currentData['status'] as String? ?? 'submitted').toLowerCase();
      final isPendingLike = const {'submitted', 'resubmitted', 'pending', ''}
          .contains(currentStatus);
      var isResubmittedAfterReview = false;
      if (currentStatus == 'verified' || currentStatus == 'approved') {
        final submittedAt = KycReviewSubmission._parseTs(
            currentData['submittedAt'] ?? currentData['updatedAt']);
        final reviewedAt = KycReviewSubmission._parseTs(
            currentData['reviewed_at'] ??
                currentData['reviewedAt'] ??
                currentData['verifiedAt'] ??
                currentData['decidedAt']);
        isResubmittedAfterReview = submittedAt != null &&
            reviewedAt != null &&
            submittedAt.isAfter(reviewedAt);
      }
      if (!isPendingLike && !isResubmittedAfterReview) {
        return false;
      }
      await firestore.collection('kyc_documents').doc(customerId).update({
        'status': decision,
        if (decision == 'rejected') 'rejection_reason': trimmedReason,
        if (decision == 'verified') 'rejection_reason': FieldValue.delete(),
        'reviewed_at': FieldValue.serverTimestamp(),
      });
      // Mirror approval status + reviewedAt + rejectionReason onto customers/{uid}
      // and is_verified onto users/{uid} so the admin panel and customer app stay in sync.
      try {
        final customerDoc = await firestore
            .collection('customers')
            .doc(customerId)
            .get();
        if (customerDoc.data() != null) {
          await firestore.collection('customers').doc(customerId).update({
            'approvalStatus': decision == 'verified' ? 'approved' : 'rejected',
            'reviewedAt': DateTime.now().toIso8601String(),
            if (decision == 'rejected')
              'rejectionReason': trimmedReason,
            if (decision == 'verified')
              'rejectionReason': FieldValue.delete(),
          });
        }
      } catch (_) {}
      try {
        final userDoc =
            await firestore.collection('users').doc(customerId).get();
        if (userDoc.data() != null) {
          await firestore.collection('users').doc(customerId).update({
            'is_verified': decision == 'verified',
          });
        }
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
      try {
        await NotificationDataSource(firestore: firestore)
            .createCustomerNotification(
          customerId: customerId,
          title: decision == 'verified'
              ? 'KYC documents verified'
              : 'KYC documents rejected',
          body: decision == 'verified'
              ? 'Your CNIC and driving licence have been verified. You are ready to book.'
              : 'Please review and re-upload your documents. Reason: $trimmedReason',
          type: 'kyc_status',
          targetRoute: RouteNames.customerKyc,
        );
      } catch (_) {}
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
    this.status = 'submitted',
    this.submittedAt,
    this.reviewedAt,
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
  final String status;

  /// The submission time (`updatedAt` server timestamp, written when
  /// the customer submitted). Null when the record has no timestamp.
  final DateTime? submittedAt;

  /// When an admin last approved or rejected this KYC submission.
  final DateTime? reviewedAt;

  bool get isApproved => status == 'verified' || status == 'approved';

  /// True when KYC is approved AND the customer has NOT submitted newer
  /// documents after the approval timestamp. If the customer resubmits
  /// documents (`status == 'resubmitted'` or `submittedAt > reviewedAt`),
  /// Approve re-enables automatically.
  bool get isApprovedAndUnchanged {
    if (!isApproved) return false;
    if (submittedAt != null &&
        reviewedAt != null &&
        submittedAt!.isAfter(reviewedAt!)) {
      return false;
    }
    return true;
  }

  static DateTime? _parseTs(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  factory KycReviewSubmission.fromMap(
    String customerId,
    Map<String, dynamic> data, {
    String name = '',
  }) {
    final submittedAt = _parseTs(data['submittedAt'] ?? data['updatedAt']);
    final reviewedAt = _parseTs(
      data['reviewed_at'] ??
          data['reviewedAt'] ??
          data['verifiedAt'] ??
          data['decidedAt'],
    );
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
      status: (data['status'] as String? ?? 'submitted').toLowerCase(),
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
    );
  }
}
