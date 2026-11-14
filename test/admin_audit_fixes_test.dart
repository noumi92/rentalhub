// Admin-panel audit fixes (2026-11-14) — the findings this batch owns:
// F-M2 car Hide/Reject must disappear from customer discovery,
// F-M3 the shop decision reason must reach the owner,
// F-M15 "Ask to edit" / "Warn" must have a customer-visible effect,
// F-m16 opening an announcement reports the open,
// F-M18 announcement creation is audit-logged (the log write itself
// needs a signed-in user, so here we pin the creation it logs).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/review_remote_data_source.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:rentalhub/features/notifications/presentation/views/announcement_detail_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

Map<String, dynamic> _vehicleDoc(String shopId, String plate) => {
      'shopId': shopId,
      'make': 'Toyota',
      'model': 'Corolla',
      'year': 2023,
      'plateNumber': plate,
      'category': 'Sedan',
      'transmission': 'Automatic',
      'fuelType': 'Petrol',
      'seats': 5,
      'isSelfDriveAvailable': true,
      'isWithDriverAvailable': true,
      'rates': {'daily_24': 7500},
      'status': 'available',
      'perKmPricingEnabled': true,
    };

void main() {
  group('F-M2 — car Hide/Reject disappears from customer discovery', () {
    late FakeFirebaseFirestore fake;
    late FleetRemoteDataSource fleet;
    late AdminShopsDataSource adminShops;

    setUp(() async {
      fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop-1').set({
        'shop_name': 'Meezan Rent a Car',
        'owner_id': 'uid-1',
        'verification_status': 'approved',
        'is_verified': true,
        'city': 'Lahore',
      });
      await fake.collection('vehicles').doc('v-ok').set(
          _vehicleDoc('shop-1', 'LEA-24-0001'));
      await fake.collection('vehicles').doc('v-hidden').set(
          _vehicleDoc('shop-1', 'LEA-24-0002'));
      await fake.collection('vehicles').doc('v-rejected').set(
          _vehicleDoc('shop-1', 'LEA-24-0003'));
      await fake.collection('vehicles').doc('v-approved').set(
          _vehicleDoc('shop-1', 'LEA-24-0004'));
      await fake.collection('car_reviews').doc('v-hidden').set({
        'vehicle_id': 'v-hidden',
        'status': 'hidden',
        'reason': 'Photos are blurry.',
      });
      await fake.collection('car_reviews').doc('v-rejected').set({
        'vehicle_id': 'v-rejected',
        'status': 'rejected',
        'reason': 'No registration book.',
      });
      await fake.collection('car_reviews').doc('v-approved').set({
        'vehicle_id': 'v-approved',
        'status': 'approved',
        'reason': '',
      });
      fleet = FleetRemoteDataSource(firestore: fake);
      adminShops = AdminShopsDataSource(firestore: fake);
    });

    test('customer fleet lists only unreviewed + approved cars', () async {
      final list = await fleet.getCustomerShopVehicles('shop-1');
      final ids = list.map((v) => v.vehicleId).toSet();
      expect(ids, {'v-ok', 'v-approved'});
    });

    test('owner fleet list still shows every car', () async {
      final list = await fleet.getShopVehicles('shop-1');
      expect(list.map((v) => v.vehicleId).toSet(),
          {'v-ok', 'v-hidden', 'v-rejected', 'v-approved'});
    });

    test('a hidden car cannot be opened by id from discovery', () async {
      expect(await fleet.getCustomerVehicleById('v-hidden'), isNull);
      expect(await fleet.getCustomerVehicleById('v-ok'), isNotNull);
    });

    test('setCarReview mirrors the decision onto the vehicle doc',
        () async {
      final ok = await adminShops.setCarReview(
        vehicleId: 'v-ok',
        status: 'hidden',
        reason: 'Duplicate listing.',
      );
      expect(ok, isTrue);
      final review =
          await fake.collection('car_reviews').doc('v-ok').get();
      expect(review.data()?['status'], 'hidden');
      final vehicle =
          await fake.collection('vehicles').doc('v-ok').get();
      expect(vehicle.data()?['listing_status'], 'hidden');
      final list = await fleet.getCustomerShopVehicles('shop-1');
      expect(list.map((v) => v.vehicleId).toSet(), {'v-approved'});
    });
  });

  group('F-M3 — the shop decision reason reaches the owner', () {
    late FakeFirebaseFirestore fake;
    late AdminShopsDataSource adminShops;

    setUp(() async {
      fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop-1').set({
        'shop_name': 'Meezan Rent a Car',
        'owner_id': 'uid-1',
        'verification_status': 'pending',
        'city': 'Lahore',
      });
      adminShops = AdminShopsDataSource(firestore: fake);
    });

    test('a rejection writes the reason and notifies the shop inbox',
        () async {
      final ok = await adminShops.decideShopApplication(
        shopId: 'shop-1',
        decision: 'rejected',
        reason: 'CNIC copy is unreadable.',
      );
      expect(ok, isTrue);
      final shop = await fake.collection('shops').doc('shop-1').get();
      expect(shop.data()?['verification_status'], 'rejected');
      expect(shop.data()?['rejection_reason'], 'CNIC copy is unreadable.');
      final notes =
          await fake.collection('notifications').get();
      expect(notes.docs, isNotEmpty);
      final mine = notes.docs
          .map((d) => d.data())
          .where((d) => d['shopId'] == 'shop-1')
          .toList();
      expect(mine, isNotEmpty);
      expect(mine.first['type'], 'shop_application_decided');
      expect(mine.first['body'] as String,
          contains('CNIC copy is unreadable.'));
    });

    test('ShopModel reads the reason fields back', () {
      final shop = ShopModel.fromMap({
        'shop_name': 'Meezan',
        'verification_status': 'rejected',
        'rejection_reason': 'CNIC copy is unreadable.',
        'admin_note': 'Please resubmit the bank details.',
      }, id: 'shop-1');
      expect(shop.rejectionReason, 'CNIC copy is unreadable.');
      expect(shop.adminNote, 'Please resubmit the bank details.');
    });
  });

  group('F-M15 — Ask to edit / Warn have a customer-visible effect', () {
    test('moderation helpers read the stored states', () {
      expect(
          ReviewRemoteDataSource.isEditRequested(
              {'moderation_status': 'edit_requested'}),
          isTrue);
      expect(
          ReviewRemoteDataSource.isWarned({'moderation_status': 'warned'}),
          isTrue);
      expect(
          ReviewRemoteDataSource.moderationStatusOf(
              {'moderation_status': 'hidden'}),
          'hidden');
      expect(ReviewRemoteDataSource.moderationReasonOf(
          {'moderation_reason': 'Fix the wording.'}),
          'Fix the wording.');
    });

    test('submitting an edit clears an edit request', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('reviews').doc('b1').set({
        'bookingId': 'b1',
        'shopId': 'shop-1',
        'customerId': 'cust-1',
        'shopRating': 1,
        'vehicleRating': 1,
        'customerComment': 'bad',
        'customerRatedAt': '2026-11-10T10:00:00Z',
        'moderation_status': 'edit_requested',
        'moderation_reason': 'Fix the wording.',
      });
      final ds = ReviewRemoteDataSource(firestore: fake);
      final saved = await ds.submitCustomerReview(
        bookingId: 'b1',
        shopId: 'shop-1',
        customerId: 'cust-1',
        shopRating: 4,
        vehicleRating: 4,
        comment: 'Fixed wording.',
      );
      expect(saved, isTrue);
      final doc = await fake.collection('reviews').doc('b1').get();
      expect(doc.data()?['moderation_status'], 'visible');
      expect(doc.data()?['moderation_reason'], '');
      expect(doc.data()?['edited_after_moderation_request'], isTrue);
    });
  });

  group('F-m16 — opening an announcement reports the open', () {
    testWidgets('the open is reported once for a real document',
        (tester) async {
      final reported = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AnnouncementDetailView(
            announcementId: 'ann-1',
            loader: (_) async => {
              'title_en': 'Eid offer',
              'body_en': 'All cars 20% off this weekend.',
              'created_at': '2026-11-09T10:00:00Z',
            },
            onOpened: (id) async => reported.add(id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Eid offer'), findsOneWidget);
      expect(reported, ['ann-1']);
    });

    testWidgets('no open is reported for a missing announcement',
        (tester) async {
      final reported = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AnnouncementDetailView(
            announcementId: 'ann-1',
            loader: (_) async => null,
            onOpened: (id) async => reported.add(id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reported, isEmpty);
    });
  });

  group('F-M18 — announcement creation (audit-logged write)', () {
    test('a scheduled announcement is stored as scheduled', () async {
      final fake = FakeFirebaseFirestore();
      final ds = AdminSupportDataSource(firestore: fake);
      final id = await ds.createAnnouncement(
        titleEn: 'Eid offer',
        titleUr: 'عید آفر',
        bodyEn: 'All cars 20% off.',
        bodyUr: 'تمام گاڑیاں 20 فیصد چھوٹ۔',
        audienceRole: 'all',
        audienceCity: 'Lahore',
        audiencePlan: 'all',
        channel: 'push',
        scheduledAt: DateTime(2026, 11, 20, 9, 30),
      );
      expect(id, isNotNull);
      final doc =
          await fake.collection('announcements').doc(id!).get();
      expect(doc.data()?['status'], 'scheduled');
      expect(doc.data()?['title_ur'], 'عید آفر');
    });
  });
}
