import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rentalhub/core/auth/account_deletion_service.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_play_purchase_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_buy_credits_view.dart';
import 'package:rentalhub/features/settings/presentation/widgets/delete_account_section.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
  });

  tearDown(() async => sl.reset());

  group('Play Store Compliance — Account Deletion', () {
    test('AccountDeletionService removes personal docs and keeps bookings',
        () async {
      final fs = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'cust-del-1', email: 'test@rentalhub.pk'),
      );
      await fs.collection('customers').doc('cust-del-1').set({'name': 'Ali'});
      await fs
          .collection('kyc_documents')
          .doc('cust-del-1')
          .set({'cnicNumber': '35202-1234567-1'});
      await fs.collection('users').doc('cust-del-1').set({
        'role': 'customer',
        'fcm_token': 'abc',
      });
      await fs.collection('notifications').doc('n1').set({
        'customerId': 'cust-del-1',
        'title': 'Test',
      });
      await fs.collection('bookings').doc('b1').set({
        'customerId': 'cust-del-1',
        'status': 'completed',
      });

      final service = AccountDeletionService(auth: auth, firestore: fs);
      final res = await service.deleteCurrentAccount(isOwner: false);

      expect(res.status, AccountDeletionStatus.success);
      expect((await fs.collection('customers').doc('cust-del-1').get()).exists,
          isFalse);
      expect(
          (await fs.collection('kyc_documents').doc('cust-del-1').get()).exists,
          isFalse);
      expect(
          (await fs.collection('users').doc('cust-del-1').get()).exists, isFalse);
      expect(
          (await fs.collection('notifications').doc('n1').get()).exists, isFalse);
      // Legally required booking record stays intact
      expect((await fs.collection('bookings').doc('b1').get()).exists, isTrue);
    });

    testWidgets(
        'DeleteAccountTile appears in CustomerSettingsView and OwnerSettingsView',
        (tester) async {
      await tester.pumpWidget(_wrap(const CustomerSettingsView()));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountTile), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      await tester.pumpWidget(_wrap(const OwnerSettingsView()));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteAccountTile), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets(
        'DeleteAccountTile requires confirmation checkbox before deleting',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'cust-del-2', email: 'ali@rentalhub.pk'),
      );
      var deletedCallbackFired = false;

      await tester.pumpWidget(_wrap(Scaffold(
        body: DeleteAccountTile(
          isOwner: false,
          service: AccountDeletionService(auth: auth, firestore: fs),
          onDeleted: () => deletedCallbackFired = true,
        ),
      )));

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Confirm button disabled before checkbox is ticked
      final confirmBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete Permanently'),
      );
      expect(confirmBtn.onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Permanently'));
      await tester.pumpAndSettle();

      expect(deletedCallbackFired, isTrue);
    });
  });

  group('Play Store Compliance — Option B Payments Policy (Android)', () {
    testWidgets(
        'OwnerSubscriptionPlayPurchaseView hides bank transfer checkout on Android',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OwnerSubscriptionPlayPurchaseView(planId: 'pro')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Pay by bank transfer'), findsNothing);
      expect(find.textContaining('v1.0 launch'), findsOneWidget);
    });

    testWidgets(
        'OwnerWhatsappBuyCreditsView shows Coming Soon and hides buy button',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerWhatsappBuyCreditsView()));
      await tester.pumpAndSettle();

      expect(find.text('Buy pack'), findsNothing);
      expect(find.text('Buy this pack'), findsNothing);
      expect(find.text('WhatsApp Messaging — Coming Soon'), findsOneWidget);
    });
  });
}
