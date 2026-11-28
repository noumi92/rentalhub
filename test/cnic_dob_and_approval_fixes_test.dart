import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/utils/cnic_input_formatter.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_kyc_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/kyc_draft.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step1_cnic.dart';
import 'package:rentalhub/features/owner/presentation/views/add_customer/step3_docs.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  group('CnicInputFormatter', () {
    const formatter = CnicInputFormatter();

    TextEditingValue apply(String raw) => formatter.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(
            text: raw,
            selection: TextSelection.collapsed(offset: raw.length),
          ),
        );

    test('automatically inserts hyphens after 5th and 12th digits', () {
      expect(apply('35201').text, '35201');
      expect(apply('352011').text, '35201-1');
      expect(apply('352011234567').text, '35201-1234567');
      expect(apply('3520112345671').text, '35201-1234567-1');
      expect(apply('3520112345671999').text, '35201-1234567-1');
    });

    test('strips letters and handles pasted hyphenated CNICs', () {
      expect(apply('35201-1234567-1').text, '35201-1234567-1');
      expect(apply('35201abc1234567xyz1').text, '35201-1234567-1');
    });
  });

  group('Walk-in wizard: optional license & DOB datepicker', () {
    testWidgets('Step3Docs passes validation without license pics when terms agreed',
        (tester) async {
      final key = GlobalKey<Step3DocsState>();
      final draft = KycDraft()..termsAgreed = true;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Step3Docs(key: key, draft: draft, onChanged: () {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(await key.currentState!.validate(), isTrue);
    });

    testWidgets('Step1Cnic shows DOB datepicker icon and auto-formats CNIC',
        (tester) async {
      final draft = KycDraft();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Step1Cnic(draft: draft, onChanged: () {}),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('step1_dob_picker')), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'CNIC Number'),
        '3520112345671',
      );
      await tester.pump();
      expect(draft.cnic, '35201-1234567-1');
    });
  });

  group('Admin approvals: online customer KYC & shop owner', () {
    test('decideKyc approves pending/submitted KYC and syncs customers + users',
        () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').doc('u1').set({'is_verified': false});
      await fs.collection('customers').doc('u1').set({
        'approvalStatus': 'pending',
        'source': 'online',
      });
      await fs.collection('kyc_documents').doc('u1').set({
        'status': 'pending',
        'cnicNumber': '35201-1234567-1',
      });

      final ds = AdminKycDataSource(firestore: fs);
      final ok = await ds.decideKyc(
        customerId: 'u1',
        decision: 'verified',
        adminRole: 'super_admin',
      );
      expect(ok, isTrue);

      final kyc = await fs.collection('kyc_documents').doc('u1').get();
      final cust = await fs.collection('customers').doc('u1').get();
      final user = await fs.collection('users').doc('u1').get();
      expect(kyc.data()?['status'], 'verified');
      expect(cust.data()?['approvalStatus'], 'approved');
      expect(user.data()?['is_verified'], isTrue);

      final loaded = await ds.getKycSubmission('u1');
      expect(loaded?.isApproved, isTrue);
      expect(loaded?.reviewedAt, isNotNull);
    });

    test('decideShopApplication approves rejected/pending shop and verifies owner user',
        () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('users').doc('owner1').set({'is_verified': false});
      await fs.collection('shops').doc('shop_owner1').set({
        'owner_id': 'owner1',
        'shop_name': 'Test Motors',
        'verification_status': 'rejected',
        'is_verified': false,
      });

      final ds = AdminShopsDataSource(firestore: fs);
      final ok = await ds.decideShopApplication(
        shopId: 'shop_owner1',
        decision: 'approved',
        adminRole: 'super_admin',
      );
      expect(ok, isTrue);

      final shop = await fs.collection('shops').doc('shop_owner1').get();
      final owner = await fs.collection('users').doc('owner1').get();
      expect(shop.data()?['verification_status'], 'approved');
      expect(shop.data()?['is_verified'], isTrue);
      expect(owner.data()?['is_verified'], isTrue);
    });
  });
}
