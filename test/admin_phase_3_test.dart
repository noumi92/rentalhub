import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_kyc_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_platform_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/data/services/admin_queue_counts_service.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_announcement_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_queues_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_shops_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/customer_detail_actions.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Phase 3 — admin panel CRUD gaps: Approvals as a Shops filter,
// announcement detail with edit/delete, decision validation
// (dispute cap, status preconditions, KYC mirror), server search +
// pagination, audit/authorship, blacklist cross-links and the
// reasonCategory enum, and the batch car review.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Future<FakeFirebaseFirestore> seededShops() async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('shops').doc('shop-1').set({
      'shop_name': 'Metro Car Rentals',
      'owner_id': 'owner-1',
      'owner_name': 'Ahmed Raza',
      'verification_status': 'approved',
      'city': 'Lahore',
    });
    await fake.collection('shops').doc('shop-2').set({
      'shop_name': 'Lahore Motors',
      'owner_id': 'owner-2',
      'owner_name': 'Ahmed Raza',
      'verification_status': 'pending',
      'city': 'Karachi',
    });
    await fake.collection('shops').doc('shop-3').set({
      'shop_name': 'New Wheels Rent a Car',
      'owner_id': 'owner-3',
      'owner_name': 'Ahmed Raza',
      'verification_status': 'pending',
      'city': 'Islamabad',
    });
    return fake;
  }

  group('3.1 — Approvals is a filter on the Shops list', () {
    test('the Approvals route is gone; the Shops route takes ?filter=',
        () {
      expect(RouteNames.adminShops, '/admin/shops');
      expect(RouteNames.adminAnnouncementDetail,
          '/admin/announcements/:announcementId');
    });

    test('getShopsPage filters pending server-side and counts it',
        () async {
      final fake = await seededShops();
      final ds = AdminShopsDataSource(firestore: fake);
      final page = await ds.getShopsPage(
          limit: 1, statusFilter: 'pending');
      expect(page.items.length, 1);
      expect(page.hasMore, isTrue);
      expect(page.total, 2);
      final next = await ds.getShopsPage(
          limit: 1, cursor: page.cursor, statusFilter: 'pending');
      expect(next.items.length, 1);
      expect(next.hasMore, isFalse);
      expect(await ds.countShops(statusFilter: 'pending'), 2);
      expect(await ds.countShops(statusFilter: 'all'), 3);
    });

    test('searchShops finds by name, city and owner', () async {
      final fake = await seededShops();
      final ds = AdminShopsDataSource(firestore: fake);
      expect(
          (await ds.searchShops('metro')).map((s) => s.shopId), ['shop-1']);
      expect((await ds.searchShops('karachi')).map((s) => s.shopId),
          ['shop-2']);
      expect((await ds.searchShops('ahmed')).length, 3);
      expect(await ds.searchShops('zzz'), isEmpty);
    });

    testWidgets('Queues hub Approvals row opens Shops ?filter=pending',
        (tester) async {
      const counts = AdminQueueCounts(
        approvals: 2,
        kyc: 0,
        cars: 0,
        disputes: 0,
        reviews: 0,
        tickets: 0,
      );
      final router = GoRouter(
        initialLocation: RouteNames.adminQueues,
        routes: [
          GoRoute(
              path: RouteNames.adminQueues,
              builder: (_, __) => AdminQueuesView(
                    loadCounts: () async => counts,
                    showKycReview: false,
                  )),
          GoRoute(
              path: RouteNames.adminShops,
              builder: (_, state) => Scaffold(
                  body: Text(
                      'filter=${state.uri.queryParameters['filter']}'))),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Approvals'), findsOneWidget);
      expect(find.text('2 open'), findsOneWidget);
      await tester.tap(find.text('Approvals'));
      await tester.pumpAndSettle();
      expect(find.text('filter=pending'), findsOneWidget);
    });

    testWidgets('shops list starts on the Pending filter when asked',
        (tester) async {
      final fake = await seededShops();
      sl.unregister<AdminShopsDataSource>();
      sl.registerSingleton<AdminShopsDataSource>(
          AdminShopsDataSource(firestore: fake));
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminShopsView(initialFilter: 'pending'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Lahore Motors'), findsOneWidget);
      expect(find.text('New Wheels Rent a Car'), findsOneWidget);
      expect(find.text('Metro Car Rentals'), findsNothing);
      expect(find.text('Showing 2'), findsOneWidget);
    });
  });

  group('3.2 — announcement detail: edit/delete drafts, sent read-only',
      () {
    Future<FakeFirebaseFirestore> seededAnnouncements() async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('announcements').doc('ann-draft').set({
        'title_en': 'Draft offer',
        'title_ur': 'مسودہ پیشکش',
        'body_en': 'Draft body',
        'body_ur': 'مسودہ متن',
        'audience_role': 'all',
        'audience_city': 'all',
        'audience_plan': 'all',
        'channel': 'push',
        'status': 'draft',
        'stats_sent': 0,
        'stats_delivered': 0,
        'stats_opened': 0,
        'created_at': Timestamp.fromDate(DateTime(2026, 11, 20)),
      });
      await fake.collection('announcements').doc('ann-sent').set({
        'title_en': 'Sent offer',
        'title_ur': 'بھیجا گیا اعلان',
        'body_en': 'Sent body',
        'body_ur': 'بھیجا گیا متن',
        'audience_role': 'all',
        'audience_city': 'all',
        'audience_plan': 'all',
        'channel': 'push',
        'status': 'sent',
        'stats_sent': 42,
        'stats_delivered': 0,
        'stats_opened': 3,
        'created_at': Timestamp.fromDate(DateTime(2026, 11, 19)),
      });
      await fake.collection('announcements').doc('ann-sched').set({
        'title_en': 'Scheduled offer',
        'title_ur': '',
        'body_en': 'Scheduled body',
        'body_ur': '',
        'audience_role': 'customer',
        'audience_city': 'Lahore',
        'audience_plan': 'all',
        'channel': 'push',
        'status': 'scheduled',
        'scheduled_at': '2026-12-01T10:00:00.000Z',
        'stats_sent': 0,
        'stats_delivered': 0,
        'stats_opened': 0,
        'created_at': Timestamp.fromDate(DateTime(2026, 11, 18)),
      });
      return fake;
    }

    test('a draft can be edited and deleted; a sent one cannot',
        () async {
      final fake = await seededAnnouncements();
      final ds = AdminSupportDataSource(firestore: fake);
      expect(
          await ds.updateAnnouncement(
            announcementId: 'ann-draft',
            titleEn: 'Edited offer',
            titleUr: 'ترمیم شدہ پیشکش',
            bodyEn: 'Edited body',
            bodyUr: 'ترمیم شدہ متن',
            audienceRole: 'all',
            audienceCity: 'all',
            audiencePlan: 'all',
            channel: 'push',
            adminRole: 'super_admin',
          ),
          isTrue);
      final edited =
          await fake.collection('announcements').doc('ann-draft').get();
      expect(edited.data()?['title_en'], 'Edited offer');
      expect(edited.data()?['status'], 'draft');
      expect(
          await ds.updateAnnouncement(
            announcementId: 'ann-sent',
            titleEn: 'Rewritten',
            titleUr: '',
            bodyEn: 'x',
            bodyUr: '',
            audienceRole: 'all',
            audienceCity: 'all',
            audiencePlan: 'all',
            channel: 'push',
            adminRole: 'super_admin',
          ),
          isFalse);
      expect(
          await ds.deleteAnnouncement('ann-sent',
              adminRole: 'super_admin'),
          isFalse);
      expect(
          await ds.deleteAnnouncement('ann-draft',
              adminRole: 'super_admin'),
          isTrue);
      expect(
          (await fake.collection('announcements').doc('ann-draft').get())
              .data(),
          isNull);
      expect(
          (await fake.collection('announcements').doc('ann-sent').get())
              .data(),
          isNotNull);
    });

    test('a scheduled announcement can be edited and deleted', () async {
      final fake = await seededAnnouncements();
      final ds = AdminSupportDataSource(firestore: fake);
      expect(
          await ds.updateAnnouncement(
            announcementId: 'ann-sched',
            titleEn: 'Still scheduled',
            titleUr: '',
            bodyEn: 'body',
            bodyUr: '',
            audienceRole: 'customer',
            audienceCity: 'Lahore',
            audiencePlan: 'all',
            channel: 'push',
            scheduledAt: DateTime.utc(2026, 12, 2, 10),
            adminRole: 'operations',
          ),
          isTrue);
      final doc =
          await fake.collection('announcements').doc('ann-sched').get();
      expect(doc.data()?['status'], 'scheduled');
      expect(
          await ds.deleteAnnouncement('ann-sched',
              adminRole: 'super_admin'),
          isTrue);
    });

    test('announcements page paginates and counts the total', () async {
      final fake = await seededAnnouncements();
      final ds = AdminSupportDataSource(firestore: fake);
      final first = await ds.getAnnouncementsPage(limit: 2);
      expect(first.items.length, 2);
      expect(first.hasMore, isTrue);
      expect(first.total, 3);
      final second = await ds.getAnnouncementsPage(
          limit: 2, cursor: first.cursor);
      expect(second.items.length, 1);
      expect(second.hasMore, isFalse);
    });

    testWidgets('detail view offers Edit/Delete for a draft',
        (tester) async {
      final fake = await seededAnnouncements();
      sl.unregister<AdminSupportDataSource>();
      sl.registerSingleton<AdminSupportDataSource>(
          AdminSupportDataSource(firestore: fake));
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminAnnouncementDetailView(
            announcementId: 'ann-draft'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Draft offer'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete announcement'), findsOneWidget);
      expect(
          find.text('Sent announcements are read-only history.'),
          findsNothing);
    });

    testWidgets('detail view is read-only for a sent announcement',
        (tester) async {
      final fake = await seededAnnouncements();
      sl.unregister<AdminSupportDataSource>();
      sl.registerSingleton<AdminSupportDataSource>(
          AdminSupportDataSource(firestore: fake));
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AdminAnnouncementDetailView(
            announcementId: 'ann-sent'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Sent offer'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete announcement'), findsNothing);
      expect(find.text('Sent announcements are read-only history.'),
          findsOneWidget);
    });
  });

  group('3.3a — dispute amount capped at balance + held deposit', () {
    test('the cap is remaining balance plus the collected deposit', () {
      expect(
          AdminPlatformDataSource.disputeAmountCap(
              remainingBalance: 4000, depositHeld: 5000),
          9000);
      expect(
          AdminPlatformDataSource.disputeAmountCap(
              remainingBalance: 0, depositHeld: 0),
          0);
    });

    Future<FakeFirebaseFirestore> seededDispute(
        {required int remaining,
        int? depositAmount,
        String depositStatus = 'collected',
        double? bookingDeposit}) async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('disputes').doc('dsp-1').set({
        'bookingId': 'b-1',
        'shopId': 'shop-1',
        'customerId': 'cust-1',
        'category': 'Damage claim',
        'description': 'Scratched bumper.',
        'status': 'open',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 20)),
      });
      await fake.collection('bookings').doc('b-1').set({
        'customerId': 'cust-1',
        'shopId': 'shop-1',
        'vehicleId': 'v-1',
        'totalAmount': 10000,
        'remainingBalance': remaining,
        'status': 'disputed',
        if (bookingDeposit != null) 'depositAmountPkr': bookingDeposit,
      });
      if (depositAmount != null) {
        await fake.collection('security_deposits').doc('b-1').set({
          'depositId': 'b-1',
          'bookingId': 'b-1',
          'customerId': 'cust-1',
          'shopId': 'shop-1',
          'amount': depositAmount,
          'status': depositStatus,
        });
      }
      return fake;
    }

    test('an amount over the cap is refused, at the cap it lands',
        () async {
      final fake = await seededDispute(remaining: 4000, depositAmount: 5000);
      final ds = AdminPlatformDataSource(firestore: fake);
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-1',
            decision: 'partial',
            decisionAmount: 9001,
            adminNote: 'Too much.',
            adminRole: 'super_admin',
          ),
          isFalse);
      final stillOpen =
          await fake.collection('disputes').doc('dsp-1').get();
      expect(stillOpen.data()?['status'], 'open');
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-1',
            decision: 'partial',
            decisionAmount: 9000,
            adminNote: 'At the cap.',
            adminRole: 'super_admin',
          ),
          isTrue);
      final decided =
          await fake.collection('disputes').doc('dsp-1').get();
      expect(decided.data()?['status'], 'resolved');
      expect(decided.data()?['decision_amount'], 9000);
    });

    test('a released deposit no longer counts toward the cap', () async {
      final fake = await seededDispute(
          remaining: 4000, depositAmount: 5000, depositStatus: 'released');
      final ds = AdminPlatformDataSource(firestore: fake);
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-1',
            decision: 'partial',
            decisionAmount: 4001,
            adminNote: 'Deposit was released.',
            adminRole: 'super_admin',
          ),
          isFalse);
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-1',
            decision: 'partial',
            decisionAmount: 4000,
            adminNote: 'Balance only.',
            adminRole: 'super_admin',
          ),
          isTrue);
    });

    test('without a deposit record the booking deposit field is used',
        () async {
      final fake = await seededDispute(
          remaining: 4000, bookingDeposit: 2000);
      final ds = AdminPlatformDataSource(firestore: fake);
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-1',
            decision: 'partial',
            decisionAmount: 6001,
            adminNote: 'Over.',
            adminRole: 'super_admin',
          ),
          isFalse);
    });

    test('a dispute whose booking cannot be read is refused', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('disputes').doc('dsp-x').set({
        'bookingId': 'missing-booking',
        'status': 'open',
      });
      final ds = AdminPlatformDataSource(firestore: fake);
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-x',
            decision: 'partial',
            decisionAmount: 100,
            adminNote: 'No booking.',
            adminRole: 'super_admin',
          ),
          isFalse);
    });
  });

  group('3.3b — status preconditions on re-decisions', () {
    test('an already-resolved dispute cannot be re-decided', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('disputes').doc('dsp-1').set({
        'bookingId': 'b-1',
        'status': 'resolved',
        'decision': 'partial',
        'decision_amount': 1000,
      });
      final ds = AdminPlatformDataSource(firestore: fake);
      expect(
          await ds.decideDispute(
            disputeId: 'dsp-1',
            decision: 'full_to_owner',
            decisionAmount: 0,
            adminNote: 'Second try.',
            adminRole: 'super_admin',
          ),
          isFalse);
    });

    test('an already-approved shop cannot be re-rejected, nor vice versa',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('shops').doc('shop-ok').set({
        'shop_name': 'Approved Shop',
        'verification_status': 'approved',
      });
      await fake.collection('shops').doc('shop-no').set({
        'shop_name': 'Rejected Shop',
        'verification_status': 'rejected',
      });
      await fake.collection('shops').doc('shop-wait').set({
        'shop_name': 'Waiting Shop',
        'verification_status': 'info_requested',
      });
      final ds = AdminShopsDataSource(firestore: fake);
      expect(
          await ds.decideShopApplication(
              shopId: 'shop-ok',
              decision: 'rejected',
              reason: 'Changed my mind.',
              adminRole: 'super_admin'),
          isFalse);
      expect(
          await ds.decideShopApplication(
              shopId: 'shop-no',
              decision: 'approved',
              adminRole: 'super_admin'),
          isFalse);
      expect(
          await ds.decideShopApplication(
              shopId: 'shop-wait',
              decision: 'approved',
              adminRole: 'super_admin'),
          isTrue);
    });

    test('an already-verified KYC record cannot be re-decided', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('kyc_documents').doc('cust-v').set({
        'status': 'verified',
        'cnicNumber': '35202-1111111-1',
      });
      await fake.collection('kyc_documents').doc('cust-r').set({
        'status': 'rejected',
        'cnicNumber': '35202-2222222-2',
      });
      await fake.collection('kyc_documents').doc('cust-s').set({
        'status': 'submitted',
        'cnicNumber': '35202-3333333-3',
      });
      final ds = AdminKycDataSource(firestore: fake);
      expect(
          await ds.decideKyc(
              customerId: 'cust-v',
              decision: 'rejected',
              reason: 'Second look.',
              adminRole: 'super_admin'),
          isFalse);
      expect(
          await ds.decideKyc(
              customerId: 'cust-r',
              decision: 'verified',
              adminRole: 'super_admin'),
          isFalse);
      expect(
          await ds.decideKyc(
              customerId: 'cust-s',
              decision: 'verified',
              adminRole: 'super_admin'),
          isTrue);
    });
  });

  group('3.3c — the KYC mirror never creates an orphan customer doc',
      () {
    test('rejecting without a customers doc leaves none behind', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('kyc_documents').doc('cust-9').set({
        'status': 'submitted',
        'cnicNumber': '35202-9999999-9',
      });
      final ds = AdminKycDataSource(firestore: fake);
      expect(
          await ds.decideKyc(
              customerId: 'cust-9',
              decision: 'rejected',
              reason: 'Photo is unreadable.',
              adminRole: 'super_admin'),
          isTrue);
      final customer =
          await fake.collection('customers').doc('cust-9').get();
      expect(customer.data(), isNull);
    });

    test('rejecting with a customers doc mirrors the reason there',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('kyc_documents').doc('cust-8').set({
        'status': 'resubmitted',
        'cnicNumber': '35202-8888888-8',
      });
      await fake.collection('customers').doc('cust-8').set({
        'name': 'Sara Khan',
      });
      final ds = AdminKycDataSource(firestore: fake);
      expect(
          await ds.decideKyc(
              customerId: 'cust-8',
              decision: 'rejected',
              reason: 'Licence expired.',
              adminRole: 'super_admin'),
          isTrue);
      final customer =
          await fake.collection('customers').doc('cust-8').get();
      expect(customer.data()?['rejectionReason'], 'Licence expired.');
      expect(customer.data()?['name'], 'Sara Khan');
    });
  });

  group('3.4 — server search and pagination', () {
    test('bookings page by status and search by customer', () async {
      final fake = FakeFirebaseFirestore();
      for (var i = 0; i < 3; i++) {
        await fake.collection('bookings').doc('b-$i').set({
          'customerId': 'cust-$i',
          'customerName': i == 0 ? 'Bilal Ahmed' : 'Sara Khan',
          'shopId': 'shop-1',
          'vehicleId': 'v-1',
          'totalAmount': 5000 + i,
          'remainingBalance': 0,
          'status': i == 2 ? 'completed' : 'active',
          'pickupTime': '2026-11-2${i}T10:00:00.000Z',
          'returnTime': '2026-11-2${i}T12:00:00.000Z',
        });
      }
      final ds = AdminPlatformDataSource(firestore: fake);
      final page = await ds.getBookingsPage(status: 'active', limit: 1);
      expect(page.items.length, 1);
      expect(page.hasMore, isTrue);
      expect(page.total, 2);
      final next = await ds.getBookingsPage(
          status: 'active', limit: 1, cursor: page.cursor);
      expect(next.items.length, 1);
      expect(next.hasMore, isFalse);
      final found = await ds.searchBookings('bilal');
      expect(found.map((b) => b.bookingId), ['b-0']);
      expect(await ds.countBookings(status: 'completed'), 1);
    });

    test('status-filtered ticket pages paginate past the old 100 cap',
        () async {
      final fake = FakeFirebaseFirestore();
      for (var i = 0; i < 3; i++) {
        await fake.collection('support_tickets').doc('t-$i').set({
          'customerId': 'cust-1',
          'message': 'Ticket $i',
          'status': 'open',
          'priority': 'low',
          'createdAt': Timestamp.fromDate(
              DateTime(2026, 11, 20).add(Duration(hours: i))),
        });
      }
      await fake.collection('support_tickets').doc('t-closed').set({
        'customerId': 'cust-2',
        'message': 'Closed one',
        'status': 'closed',
        'priority': 'low',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 19)),
      });
      final ds = AdminSupportDataSource(firestore: fake);
      final first =
          await ds.getTicketsPage(status: 'open', limit: 2);
      expect(first.items.length, 2);
      expect(first.hasMore, isTrue);
      final second = await ds.getTicketsPage(
          status: 'open', limit: 2, cursor: first.cursor);
      expect(second.items.length, 1);
      expect(second.hasMore, isFalse);
      expect(second.items.first.id, isNot('t-closed'));
    });

    test('disputes, reviews, cars and KYC report their totals', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('disputes').doc('dsp-1').set({
        'bookingId': 'b-1',
        'status': 'open',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 20)),
      });
      await fake.collection('reviews').doc('rev-1').set({
        'bookingId': 'b-1',
        'shopRating': 5,
      });
      await fake.collection('vehicles').doc('v-1').set({
        'shopId': 'shop-1',
        'make': 'Toyota',
        'model': 'Corolla',
      });
      await fake.collection('kyc_documents').doc('cust-1').set({
        'status': 'submitted',
      });
      await fake.collection('kyc_documents').doc('cust-2').set({
        'status': 'verified',
      });
      final platform = AdminPlatformDataSource(firestore: fake);
      expect(await platform.countDisputes(status: 'open'), 1);
      expect(await platform.countReviews(), 1);
      final shops = AdminShopsDataSource(firestore: fake);
      expect(await shops.countCars(), 1);
      final kyc = AdminKycDataSource(firestore: fake);
      expect(await kyc.countPendingKyc(), 1);
    });
  });

  group('3.5 — audit and authorship', () {
    test('an admin note is stored with its text', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('customers').doc('cust-1').set({
        'name': 'Bilal Ahmed',
      });
      final ds = AdminPeopleDataSource(firestore: fake);
      expect(
          await ds.addCustomerNote(
              customerId: 'cust-1',
              text: 'Called the customer.',
              adminRole: 'super_admin'),
          isTrue);
      final notes = await fake
          .collection('customers')
          .doc('cust-1')
          .collection('admin_notes')
          .get();
      expect(notes.docs.length, 1);
      expect(notes.docs.first.data()['text'], 'Called the customer.');
    });

    test('pruneExpiredInvites still removes expired invites', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('admin_invites').doc('inv-old').set({
        'email': 'old@example.com',
        'admin_role': 'operations',
        'accepted': false,
        'expires_at':
            Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      await fake.collection('admin_invites').doc('inv-new').set({
        'email': 'new@example.com',
        'admin_role': 'operations',
        'accepted': false,
        'expires_at':
            Timestamp.fromDate(DateTime(2027, 1, 1)),
      });
      final ds = AdminRemoteDataSource(firestore: fake);
      expect(await ds.pruneExpiredInvites(), 1);
      expect(
          (await fake
                  .collection('admin_invites')
                  .doc('inv-old')
                  .get())
              .data(),
          isNull);
      expect(
          (await fake
                  .collection('admin_invites')
                  .doc('inv-new')
                  .get())
              .data(),
          isNotNull);
    });

    test('creating an invite persists it (audit now lives in the source)',
        () async {
      final fake = FakeFirebaseFirestore();
      final ds = AdminRemoteDataSource(firestore: fake);
      final invite = await ds.createInvite(
          email: 'ops@example.com',
          adminRole: 'operations',
          callerRole: 'super_admin');
      expect(invite.email, 'ops@example.com');
      final stored = await fake
          .collection('admin_invites')
          .doc(invite.id)
          .get();
      expect(stored.data()?['accepted'], isFalse);
    });
  });

  group('3.6 — blacklist cross-links, enum and batch car review', () {
    test('reasonCategory is a closed enum of six values', () {
      expect(
          BlacklistReasonCategory.values.map((c) => c.value).toList(),
          [
            'fraud',
            'late-return',
            'damage',
            'non-payment',
            'abusive-behaviour',
            'other',
          ]);
      expect(BlacklistReasonCategory.fromValue('damage'),
          BlacklistReasonCategory.damage);
      expect(BlacklistReasonCategory.fromValue('rude'), isNull);
      expect(BlacklistReasonCategory.fromValue(''), isNull);
    });

    test('a report splits category and description; junk is refused',
        () async {
      final fake = FakeFirebaseFirestore();
      final ds = AdminPeopleDataSource(firestore: fake);
      expect(
          await ds.reportCustomerToBlacklist(
            customerId: 'cust-1',
            cnic: '35202-1234567-1',
            phone: '03001234567',
            reasonCategory: 'rude',
            description: 'Was rude.',
            reportedByShopId: 'admin',
            adminRole: 'super_admin',
          ),
          isFalse);
      expect(
          await ds.reportCustomerToBlacklist(
            customerId: 'cust-1',
            cnic: '35202-1234567-1',
            phone: '03001234567',
            reasonCategory: 'damage',
            description: 'Returned the car with a dented door.',
            reportedByShopId: 'admin',
            adminRole: 'super_admin',
          ),
          isTrue);
      final records =
          await fake.collection('blacklist').get();
      expect(records.docs.length, 1);
      expect(records.docs.first.data()['reasonCategory'], 'damage');
      expect(records.docs.first.data()['description'],
          'Returned the car with a dented door.');
    });

    test('a tribunal CNIC resolves to its customer record', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('customers').doc('cust-7').set({
        'name': 'Bilal Ahmed',
        'cnic': '35202-7654321-1',
        'phone': '03009876543',
      });
      final ds = AdminPeopleDataSource(firestore: fake);
      expect(await ds.getCustomerIdByCnic('35202-7654321-1'), 'cust-7');
      expect(await ds.getCustomerIdByCnic('35202-0000000-0'), isNull);
    });

    test('setCarReview writes the review and the listing together',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('vehicles').doc('v-1').set({
        'shopId': 'shop-1',
        'make': 'Toyota',
        'model': 'Corolla',
        'listing_status': 'approved',
      });
      final ds = AdminShopsDataSource(firestore: fake);
      expect(
          await ds.setCarReview(
              vehicleId: 'v-1',
              status: 'hidden',
              reason: 'Photos do not match the car.',
              adminRole: 'super_admin'),
          isTrue);
      final review =
          await fake.collection('car_reviews').doc('v-1').get();
      expect(review.data()?['status'], 'hidden');
      final vehicle =
          await fake.collection('vehicles').doc('v-1').get();
      expect(vehicle.data()?['listing_status'], 'hidden');
    });

    testWidgets('the blacklist dialog returns category + description',
        (tester) async {
      BlacklistReportReason? result;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showBlacklistReportDialog(
                  tester.element(find.text('Open')));
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Report to blacklist?'), findsOneWidget);
      await tester.tap(
          find.byType(DropdownButtonFormField<BlacklistReasonCategory>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Damage').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextField), 'Returned the car with a dented door.');
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.category, BlacklistReasonCategory.damage);
      expect(result!.description, 'Returned the car with a dented door.');
    });
  });
}
