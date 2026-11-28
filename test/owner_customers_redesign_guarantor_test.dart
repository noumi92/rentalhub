import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/customer_detail_body.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_kyc_slots.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: child),
      );

  group('Guarantor model & draft round-trip', () {
    test('CustomerModel persists inline guarantor fields cleanly', () {
      final model = CustomerModel(
        customerId: 'cust-g-test',
        shopId: 'shop-1',
        name: 'Bilal Tariq',
        phone: '0300-1112233',
        cnic: '35201-1234567-1',
        createdAt: DateTime.utc(2026, 11, 20),
        guarantorName: 'Usman Ali',
        guarantorPhone: '0321-7654321',
        guarantorCnic: '35202-7654321-3',
        guarantorRelation: 'Family',
        guarantorAddress: 'Model Town, Lahore',
      );
      final restored = CustomerModel.fromMap(model.toMap(), 'cust-g-test');
      expect(restored.guarantorName, 'Usman Ali');
      expect(restored.guarantorPhone, '0321-7654321');
      expect(restored.guarantorCnic, '35202-7654321-3');
      expect(restored.guarantorRelation, 'Family');
      expect(restored.guarantorAddress, 'Model Town, Lahore');
    });

    test('KycDraft.fromEntity prefills inline guarantor fields', () {
      final entity = CustomerEntity(
        customerId: 'cust-g-draft',
        shopId: 'shop-1',
        name: 'Bilal Tariq',
        phone: '0300-1112233',
        cnic: '35201-1234567-1',
        createdAt: DateTime.utc(2026, 11, 20),
        guarantorName: 'Usman Ali',
        guarantorPhone: '0321-7654321',
        guarantorCnic: '35202-7654321-3',
        guarantorRelation: 'Colleague',
        guarantorAddress: 'DHA Phase 5, Lahore',
      );
      final draft = KycDraft.fromEntity(entity);
      expect(draft.hasGuarantor, isTrue);
      expect(draft.guarantorName, 'Usman Ali');
      expect(draft.guarantorPhone, '0321-7654321');
      expect(draft.guarantorCnic, '35202-7654321-3');
      expect(draft.guarantorRelation, 'Colleague');
      expect(draft.guarantorAddress, 'DHA Phase 5, Lahore');
    });
  });

  group('4-slot CNIC & Driving License KYC', () {
    test('kycTotalSlots is strictly 4 and ignores legacy biometric URLs', () {
      expect(kycTotalSlots, 4);
      final legacyOnly = CustomerEntity(
        customerId: 'cust-legacy',
        shopId: 'shop-1',
        name: 'Legacy User',
        phone: '0300-0000000',
        createdAt: DateTime.utc(2026, 11, 1),
        profilePhotoUrl: 'https://example.invalid/face.jpg',
        leftFingerprintUrl: 'https://example.invalid/l.jpg',
        rightFingerprintUrl: 'https://example.invalid/r.jpg',
        utilityBillUrl: 'https://example.invalid/bill.jpg',
        signatureUrl: 'https://example.invalid/sig.png',
      );
      expect(kycUploadedCount(legacyOnly), 0);
      expect(isKycCompleteForEntity(legacyOnly), isFalse);

      final complete = legacyOnly.copyWith(
        cnicFrontUrl: 'https://example.invalid/cf.jpg',
        cnicBackUrl: 'https://example.invalid/cb.jpg',
        licenseFrontUrl: 'https://example.invalid/lf.jpg',
        licenseBackUrl: 'https://example.invalid/lb.jpg',
      );
      expect(kycUploadedCount(complete), 4);
      expect(isKycCompleteForEntity(complete), isTrue);
    });
  });

  group('Redesigned CustomerDetailBody — Add KYC & Guarantor card', () {
    testWidgets('Add KYC button jumps to KYC tab; Personal Info shows guarantor',
        (tester) async {
      final customer = CustomerEntity(
        customerId: 'cust-redesign-1',
        shopId: 'shop-1',
        name: 'Solution PK',
        phone: '0312-9231066',
        cnic: '35201-5555555-5',
        createdAt: DateTime.utc(2026, 11, 20),
        guarantorName: 'Imran Raza',
        guarantorPhone: '0300-9876543',
        guarantorCnic: '35202-1122334-5',
        guarantorRelation: 'Friend',
        guarantorAddress: 'Gulberg III, Lahore',
      );
      await tester.pumpWidget(wrap(CustomerDetailBody(
        customer: customer,
        bookings: const [],
        blacklisted: false,
        shopId: 'shop-1',
        acting: false,
        onApprove: () {},
        onReject: () {},
        onBlockToggle: () {},
        onEdit: () {},
        onArchive: () {},
        onReplaceSlot: (_) {},
      )));
      await tester.pumpAndSettle();

      // Actionable KYC strip switches straight to the 4-slot KYC tab.
      expect(find.byKey(const ValueKey('customer_detail_add_kyc_btn')),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('customer_detail_add_kyc_btn')));
      await tester.pumpAndSettle();
      expect(find.text('0 / 4 Uploaded'), findsOneWidget);
      expect(find.text('CNIC front'), findsOneWidget);
      expect(find.text('License back'), findsOneWidget);

      // Personal Info tab renders the dedicated Guarantor Information card.
      await tester.ensureVisible(
          find.byKey(const ValueKey('customer_detail_tab_1')));
      await tester.tap(find.byKey(const ValueKey('customer_detail_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('Guarantor Information'), findsOneWidget);
      expect(find.text('Imran Raza'), findsOneWidget);
      expect(find.text('0300-9876543'), findsOneWidget);
      expect(find.text('35202-1122334-5'), findsOneWidget);
      expect(find.text('Friend'), findsOneWidget);
      expect(find.text('Gulberg III, Lahore'), findsOneWidget);
    });
  });
}
