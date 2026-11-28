import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/network/firestore_service.dart';
import '../../trust/data/datasources/kyc_remote_data_source.dart';
import '../../trust/data/services/trust_score_service.dart';
import '../../trust/domain/entities/kyc_document_entity.dart';
import '../data/datasources/customer_remote_data_source.dart';
import '../data/datasources/review_remote_data_source.dart';
import '../domain/entities/customer_entity.dart';

/// Profile hub (2026-11-25): the customer's profile, KYC and
/// reputation used to be loaded three separate times — once in the
/// profile view, once in the reputation view, once on Home (trust
/// score computed three times via [TrustScoreService]). The hub
/// loads it all once and hands the same data to both tabs.
class ProfileHubData {
  const ProfileHubData({
    required this.name,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.photoUrl,
    required this.dateOfBirth,
    required this.fatherName,
    required this.address,
    required this.trustScore,
    required this.kycStatus,
    required this.isBlacklisted,
    required this.loading,
    required this.loadFailed,
    required this.kyc,
    required this.rejectionReason,
    required this.ownerReviews,
    required this.customer,
  });

  final String name;
  final String email;
  final String phone;
  final String cnic;
  final String? photoUrl;
  final String? dateOfBirth;
  final String? fatherName;
  final String? address;
  final double? trustScore;

  /// The KYC status string from `kyc_documents/{uid}` — '' when the
  /// customer has no submission yet.
  final String kycStatus;
  final bool isBlacklisted;
  final bool loading;
  final bool loadFailed;
  final KycDocumentEntity? kyc;
  final String? rejectionReason;

  /// Owner ratings of this customer (care/punctuality/behaviour),
  /// for the trust section on the Profile tab.
  final List<Map<String, dynamic>> ownerReviews;

  /// The full `customers` record, for the edit flow.
  final CustomerEntity? customer;

  bool get kycVerified => kycStatus == 'verified';
}

abstract final class ProfileHubLoader {
  static String uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<ProfileHubData> load() async {
    // Empty name = signed-out visitor; the view renders the
    // localized `profileGuest` label for it (never hardcoded).
    var name = '';
    var email = '';
    var phone = '';
    var cnic = '';
    String? photoUrl;
    String? dateOfBirth;
    String? fatherName;
    String? address;
    double? trustScore;
    var kycStatus = '';
    var isBlacklisted = false;
    var loadFailed = false;
    KycDocumentEntity? kyc;
    String? rejectionReason;
    var ownerReviews = <Map<String, dynamic>>[];
    CustomerEntity? customer;
    // AC-18: only a signed-in load failure counts as a failure —
    // a signed-out visitor simply stays unnamed.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        name = user.displayName ?? '';
        email = user.email ?? '';
        phone = user.phoneNumber ?? '';
        photoUrl = user.photoURL;
        try {
          double? storedTrustScore;
          if (sl.isRegistered<FirestoreService>()) {
            final record = await sl<FirestoreService>().getUser(user.uid);
            if (record != null) {
              if (name.isEmpty && record.fullName.isNotEmpty) {
                name = record.fullName;
              }
              if (email.isEmpty && record.email.isNotEmpty) {
                email = record.email;
              }
              if (phone.isEmpty && record.phoneNumber.isNotEmpty) {
                phone = record.phoneNumber;
              }
              storedTrustScore = record.trustScore;
              isBlacklisted = record.isBlacklisted;
              photoUrl ??= record.profilePhotoUrl;
            }
          }
          // Live score first (shared TrustScoreService, same as the
          // admin panel); stored trust_score is the fallback.
          trustScore =
              (await const TrustScoreService().compute(user.uid))?.breakdown.total ??
                  storedTrustScore;
          if (sl.isRegistered<CustomerRemoteDataSource>()) {
            customer = await sl<CustomerRemoteDataSource>()
                .getCustomerById(user.uid);
            if (customer != null) {
              if (customer.name.isNotEmpty) name = customer.name;
              if (customer.phone.isNotEmpty) phone = customer.phone;
              cnic = customer.cnic ?? '';
              photoUrl = customer.profilePhotoUrl ?? photoUrl;
              dateOfBirth = customer.dateOfBirth;
              fatherName = customer.fatherName;
              address = customer.address;
              rejectionReason = customer.rejectionReason;
            }
          }
          if (sl.isRegistered<KycRemoteDataSource>()) {
            kyc = await sl<KycRemoteDataSource>().getKyc(user.uid);
            kycStatus = kyc?.status ?? '';
          }
          if (sl.isRegistered<ReviewRemoteDataSource>()) {
            ownerReviews = await sl<ReviewRemoteDataSource>()
                .getCustomerReviews(user.uid, onlyOwnerRated: true);
          }
        } catch (_) {
          loadFailed = true;
        }
      }
    } catch (_) {}
    return ProfileHubData(
      name: name,
      email: email,
      phone: phone,
      cnic: cnic,
      photoUrl: photoUrl,
      dateOfBirth: dateOfBirth,
      fatherName: fatherName,
      address: address,
      trustScore: trustScore,
      kycStatus: kycStatus,
      isBlacklisted: isBlacklisted,
      loading: false,
      loadFailed: loadFailed,
      kyc: kyc,
      rejectionReason: rejectionReason,
      ownerReviews: ownerReviews,
      customer: customer,
    );
  }
}
