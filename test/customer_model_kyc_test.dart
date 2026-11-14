// Add Customer wizard (O12–O15): the new KYC fields round-trip
// through CustomerModel.toMap/fromMap, and an older record without
// them still reads fine with nulls/empty defaults.
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';

void main() {
  group('CustomerModel KYC fields', () {
    test('full wizard record round-trips', () {
      final model = CustomerModel(
        customerId: 'cust-3520212345671',
        shopId: 'shop-1',
        name: 'Ahmed Khan',
        phone: '0300-1234567',
        cnic: '35202-1234567-1',
        source: 'walk_in',
        createdAt: DateTime.utc(2026, 11, 9, 4, 0),
        dateOfBirth: '12.03.1995',
        cnicExpiry: '15.08.2031',
        fatherName: 'Muhammad Khan',
        address: 'House 45, Street 7, Johar Town, Lahore',
        profilePhotoUrl: 'https://example.invalid/kyc/face.jpg',
        thumbprintUrl: 'https://example.invalid/kyc/thumb.jpg',
        leftFingerprintUrl: 'https://example.invalid/kyc/finger-left.jpg',
        rightFingerprintUrl: 'https://example.invalid/kyc/finger-right.jpg',
        cnicFrontUrl: 'https://example.invalid/kyc/cnic-front.jpg',
        cnicBackUrl: 'https://example.invalid/kyc/cnic-back.jpg',
        licenseNumber: 'LHR-2018-45678',
        licenseExpiry: '20.01.2029',
        licenseFrontUrl: 'https://example.invalid/kyc/lic-front.jpg',
        licenseBackUrl: 'https://example.invalid/kyc/lic-back.jpg',
        utilityBillUrl: 'https://example.invalid/kyc/bill.jpg',
        extraDocumentUrls: const [
          'https://example.invalid/kyc/extra-1.jpg',
          'https://example.invalid/kyc/extra-2.jpg',
        ],
        signatureUrl: 'https://example.invalid/kyc/sig.png',
        guarantorCustomerId: 'cust-3520298765432',
        guarantorRelation: 'Friend',
      );
      final restored = CustomerModel.fromMap(model.toMap(), model.customerId);
      expect(restored, equals(model));
      expect(restored.profilePhotoUrl, model.profilePhotoUrl);
      expect(restored.extraDocumentUrls, model.extraDocumentUrls);
      expect(restored.leftFingerprintUrl, model.leftFingerprintUrl);
      expect(restored.rightFingerprintUrl, model.rightFingerprintUrl);
      expect(restored.guarantorCustomerId, 'cust-3520298765432');
      expect(restored.guarantorRelation, 'Friend');
    });

    test('legacy record without KYC fields reads with nulls', () {
      final restored = CustomerModel.fromMap({
        'customerId': 'cust-1',
        'shopId': 'shop-1',
        'name': 'Old Customer',
        'phone': '0300-0000000',
        'source': 'walk_in',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      expect(restored.profilePhotoUrl, isNull);
      expect(restored.thumbprintUrl, isNull);
      expect(restored.leftFingerprintUrl, isNull);
      expect(restored.rightFingerprintUrl, isNull);
      expect(restored.licenseNumber, isNull);
      expect(restored.extraDocumentUrls, isEmpty);
      expect(restored.signatureUrl, isNull);
      expect(restored.guarantorCustomerId, isNull);
      // And it writes back without inventing the fields.
      expect(restored.toMap().containsKey('profilePhotoUrl'), isFalse);
      expect(restored.toMap().containsKey('leftFingerprintUrl'), isFalse);
      expect(restored.toMap().containsKey('rightFingerprintUrl'), isFalse);
      expect(restored.toMap().containsKey('extraDocumentUrls'), isFalse);
    });
  });
}
