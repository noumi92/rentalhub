import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_kyc_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dashboard_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_kyc_review_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sidebar_nav.dart';
import 'package:rentalhub/features/admin/presentation/widgets/shop_application_detail_sheet.dart';
import 'package:rentalhub/features/admin/presentation/widgets/ticket_detail_sheet.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'package:rentalhub/l10n/app_localizations_en.dart';
import 'package:rentalhub/l10n/app_localizations_ur.dart';

// Phase 1 (quick wins) of the admin panel update plan: confirm
// dialogs, the hidden Subscriptions item, the removed Settings APK
// embed, dashboard truth (KYC count + one open-disputes
// definition), drag handles, 48dp dialog buttons, the KYC
// detail error ordering, and the decideKyc permission backstop.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  ShopModel shop() {
    return ShopModel(
      shopId: 'shop-1',
      ownerId: 'owner-1',
      shopName: 'Metro Car Rentals',
      phoneNumber: '03001234567',
      address: 'Main Boulevard',
      city: 'Lahore',
      geoLocation: const GeoPointEntity(31.5204, 74.3587),
      bankAccounts: const [],
      kycDocuments: const {},
      fleetPhotos: const [],
      ownerName: 'Ahmed Raza',
      cnicNumber: '35202-1234567-1',
    );
  }

  group('1.4 — dashboard truth (data layer)', () {
    test('open disputes counts any non-resolved dispute, KYC counts pending',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('kyc_documents').doc('cust-1').set(
          {'status': 'submitted'});
      await fake.collection('kyc_documents').doc('cust-2').set(
          {'status': 'resubmitted'});
      await fake.collection('kyc_documents').doc('cust-3').set(
          {'status': 'verified'});
      await fake.collection('kyc_documents').doc('cust-4').set(
          {'status': 'rejected'});
      await fake.collection('disputes').doc('d-open').set(
          {'status': 'open'});
      await fake.collection('disputes').doc('d-review').set(
          {'status': 'in_review'});
      await fake.collection('disputes').doc('d-resolved').set(
          {'status': 'resolved'});
      await fake.collection('shops').doc('shop-1').set(
          {'verification_status': 'pending'});
      await fake.collection('bookings').doc('b-1').set(
          {'status': 'active'});
      await fake.collection('support_tickets').doc('t-1').set(
          {'status': 'open'});

      final stats =
          await AdminRemoteDataSource(firestore: fake).getPlatformStats();
      // The Reports definition: open + in review, never resolved.
      expect(stats.openDisputeCount, 2);
      // Submitted + resubmitted; verified and rejected are decided.
      expect(stats.pendingKycCount, 2);
      expect(stats.shopCount, 1);
      expect(stats.activeBookingCount, 1);
      expect(stats.openTicketCount, 1);
      expect(stats.pendingShopCount, 1);
    });
  });

  group('1.4 — dashboard KYC card', () {
    testWidgets('shows the KYC queue count when the seam allows it',
        (tester) async {
      await tester.pumpWidget(wrap(
          const AdminDashboardView(showKycCard: true)));
      await tester.pumpAndSettle();
      expect(find.text('KYC submissions waiting for review'),
          findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('hidden when the seam forbids it', (tester) async {
      await tester.pumpWidget(wrap(
          const AdminDashboardView(showKycCard: false)));
      await tester.pumpAndSettle();
      expect(find.text('KYC submissions waiting for review'),
          findsNothing);
    });
  });

  group('1.4 — reports revenue label', () {
    test('booked value, not booking revenue, with a reconciliation note',
        () {
      expect(AppLocalizationsEn().admin2_reportsRevenue,
          'Booked value (incl. active)');
      expect(AppLocalizationsEn().admin2_reportsRevenueNote,
          contains('Finance income'));
      expect(AppLocalizationsUr().admin2_reportsRevenue,
          'بک شدہ قیمت (فعال سمیت)');
    });
  });

  group('1.7 — decideKyc permission backstop', () {
    test('a support role is refused without touching Firestore',
        () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('kyc_documents')
          .doc('cust-1')
          .set({'status': 'submitted'});
      final ds = AdminKycDataSource(firestore: fake);
      expect(
          await ds.decideKyc(
              customerId: 'cust-1',
              decision: 'verified',
              adminRole: 'support'),
          isFalse);
      final doc = await fake
          .collection('kyc_documents')
          .doc('cust-1')
          .get();
      expect(doc.data()?['status'], 'submitted');
    });

    test('an operations role decides and the write lands', () async {
      final fake = FakeFirebaseFirestore();
      await fake
          .collection('kyc_documents')
          .doc('cust-1')
          .set({'status': 'submitted'});
      final ds = AdminKycDataSource(firestore: fake);
      expect(
          await ds.decideKyc(
              customerId: 'cust-1',
              decision: 'verified',
              adminRole: 'operations'),
          isTrue);
      final doc = await fake
          .collection('kyc_documents')
          .doc('cust-1')
          .get();
      expect(doc.data()?['status'], 'verified');
    });
  });

  group('1.5 — KYC detail error wins over not-permitted', () {
    testWidgets('a load failure shows the error state with retry',
        (tester) async {
      await tester.pumpWidget(wrap(AdminKycReviewDetailView(
        key: UniqueKey(),
        customerId: 'cust-1',
        loadSubmission: (_) async => throw Exception('boom'),
        resolveAdminRole: () async => 'operations',
        resolveImageUrl: (_, __) => 'https://example.com/doc.jpg',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Could not load the KYC queue.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Only super admins and operations can review KYC'),
          findsNothing);
    });
  });

  group('1.1 — confirm dialogs', () {
    testWidgets('the confirm dialog buttons are 48dp tall',
        (tester) async {
      await tester.pumpWidget(wrap(Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAdminConfirmDialog(
              context,
              title: 'Do it?',
              body: 'This cannot be undone.',
            ),
            child: const Text('Open dialog'),
          ),
        ),
      )));
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Do it?'), findsOneWidget);
      final cancelSize =
          tester.getSize(find.widgetWithText(TextButton, 'Cancel'));
      final confirmSize =
          tester.getSize(find.widgetWithText(FilledButton, 'Confirm'));
      expect(cancelSize.height, greaterThanOrEqualTo(48));
      expect(confirmSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('shop approve asks first; cancel saves nothing',
        (tester) async {
      await tester.pumpWidget(wrap(Scaffold(
        body: ShopApplicationDetailSheet(
          shop: shop(),
          onDecided: () {},
        ),
      )));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm decision'), findsOneWidget);
      expect(find.text("Save 'Approve' for this shop application?"),
          findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm decision'), findsNothing);
      expect(find.text('Approve'), findsOneWidget);
    });

    testWidgets('ticket close asks first; cancel leaves the ticket open',
        (tester) async {
      final ticket = SupportTicket(
        id: 'T-1',
        customerId: 'customer-1',
        message: 'The showroom charged me extra for fuel.',
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(wrap(Scaffold(
        body: TicketDetailSheet(ticket: ticket, onChanged: () {}),
      )));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Close ticket'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close ticket'));
      await tester.pumpAndSettle();
      expect(find.text('Close this ticket?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Close this ticket?'), findsNothing);
      expect(find.text('Ticket T-1'), findsOneWidget);
    });
  });

  // Restructure (2026-11-27), Step 1: Subscriptions is no longer
  // hidden — it is shown in the Commerce group (still the Coming
  // Soon placeholder screen, not functional).
  group('1.2 — Packages & Credits shown in the sidebar', () {
    testWidgets('the sidebar lists Packages & Credits alongside core sections',
        (tester) async {
      await tester.pumpWidget(wrap(Scaffold(
          body: AdminSidebarNav(
        activeRoute: RouteNames.adminDashboard,
        onNavigate: (_) {},
        showApkDownload: false,
        showKycReview: false,
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Packages & Credits'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Platform & System'), findsOneWidget);
    });
  });
}
