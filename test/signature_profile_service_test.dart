import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/services/signature_profile_service.dart';

void main() {
  final fakePng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4,
  ]);

  group('SignatureProfileService', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('saves and loads customer signature PNG', () async {
      final before = await SignatureProfileService.loadCustomerSignature(
        'cust-1',
        firestore: firestore,
      );
      expect(before.pngBytes, isNull);

      final saved = await SignatureProfileService.saveCustomerSignature(
        'cust-1',
        fakePng,
        firestore: firestore,
      );
      expect(saved, isTrue);

      final after = await SignatureProfileService.loadCustomerSignature(
        'cust-1',
        firestore: firestore,
      );
      expect(after.pngBytes, fakePng);
    });

    test('saves and loads owner signature PNG', () async {
      await firestore.collection('shops').doc('shop_owner1').set({
        'shop_name': 'Test Shop',
      });
      final saved = await SignatureProfileService.saveOwnerSignature(
        'owner1',
        fakePng,
        firestore: firestore,
      );
      expect(saved, isTrue);

      final after = await SignatureProfileService.loadOwnerSignature(
        'owner1',
        firestore: firestore,
      );
      expect(after.pngBytes, fakePng);
    });

    test('saves and loads guarantor signature PNG (inline & linked)', () async {
      await firestore.collection('customers').doc('cust-2').set({
        'guarantorName': 'Ali Khan',
        'guarantorCustomerId': 'cust-guarantor',
      });
      final saved = await SignatureProfileService.saveGuarantorSignature(
        'cust-2',
        fakePng,
        firestore: firestore,
      );
      expect(saved, isTrue);

      final loaded = await SignatureProfileService.loadGuarantorSignature(
        'cust-2',
        firestore: firestore,
      );
      expect(loaded.name, 'Ali Khan');
      expect(loaded.pngBytes, fakePng);

      // Linked guarantor customer doc also got the signature.
      final linked = await SignatureProfileService.loadCustomerSignature(
        'cust-guarantor',
        firestore: firestore,
      );
      expect(linked.pngBytes, fakePng);
    });
  });
}
