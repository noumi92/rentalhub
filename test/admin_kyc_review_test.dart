import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_kyc_data_source.dart';
import 'package:rentalhub/features/admin/domain/admin_permissions.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_kyc_review_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_kyc_review_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_section_tabs.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sidebar_nav.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sub_tab_bar.dart';
import 'package:rentalhub/features/admin/presentation/widgets/kyc_review_document_tile.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Item 6 — admin customer-KYC review: the pending queue, the review
// detail with Approve / Reject-with-mandatory-reason, the decideKyc
// permission gate (super admin + operations), and the sidebar entry.
void main() {
  KycReviewSubmission submission({
    String id = 'cust-1',
    String name = 'Bilal Ahmed',
    String cnic = '35202-1234567-1',
    DateTime? submittedAt,
  }) {
    return KycReviewSubmission(
      customerId: id,
      customerName: name,
      cnicNumber: cnic,
      cnicFrontKey: 'kyc/cust-1/cnic-front.jpg',
      cnicBackKey: 'kyc/cust-1/cnic-back.jpg',
      licenseKey: 'kyc/cust-1/license.jpg',
      licenseBackKey: 'kyc/cust-1/license-back.jpg',
      licenseNumber: 'LHR-12345',
      licenseExpiry: '2030-01-01',
      submittedAt: submittedAt,
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('KycReviewSubmission model', () {
    test('parses every field from a Firestore map', () {
      final parsed = KycReviewSubmission.fromMap('cust-9', {
        'cnicNumber': '35202-9999999-9',
        'cnicFrontKey': 'front-key',
        'cnicBackKey': 'back-key',
        'licenseKey': 'lic-key',
        'licenseBackKey': 'lic-back-key',
        'licenseNumber': 'LHR-999',
        'licenseExpiry': '2029-05-05',
        'updatedAt': Timestamp.fromDate(DateTime(2026, 11, 14, 10, 30)),
      }, name: 'Sara Khan');
      expect(parsed.customerId, 'cust-9');
      expect(parsed.customerName, 'Sara Khan');
      expect(parsed.cnicNumber, '35202-9999999-9');
      expect(parsed.cnicFrontKey, 'front-key');
      expect(parsed.licenseNumber, 'LHR-999');
      expect(parsed.submittedAt, DateTime(2026, 11, 14, 10, 30));
    });

    test('missing fields default to empty, missing timestamp to null', () {
      final parsed = KycReviewSubmission.fromMap('cust-9', {});
      expect(parsed.cnicNumber, '');
      expect(parsed.licenseKey, '');
      expect(parsed.submittedAt, isNull);
    });

    test('parses an ISO string timestamp', () {
      final parsed = KycReviewSubmission.fromMap('cust-9', {
        'updatedAt': '2026-11-13T08:00:00.000Z',
      });
      expect(parsed.submittedAt, DateTime.utc(2026, 11, 13, 8));
    });

    test('sortNewestFirst puts the newest first, dateless last', () {
      final newer = submission(
          id: 'cust-new', submittedAt: DateTime(2026, 11, 14));
      final older = submission(
          id: 'cust-old',
          name: 'Sara Khan',
          submittedAt: DateTime(2026, 11, 12));
      final dateless = submission(id: 'cust-none', name: 'No Date');
      final sorted = AdminKycDataSource.sortNewestFirst(
          [older, dateless, newer]);
      expect(
          sorted.map((s) => s.customerId).toList(),
          ['cust-new', 'cust-old', 'cust-none']);
    });
  });

  group('AdminKycDataSource (offline)', () {
    test('queue and single reads are empty / null with no Firestore', () async {
      final ds = AdminKycDataSource();
      expect(await ds.getPendingKycSubmissions(), isEmpty);
      expect(await ds.getKycSubmission('cust-1'), isNull);
    });

    test('decisions fail honestly offline', () async {
      final ds = AdminKycDataSource();
      expect(
        await ds.decideKyc(customerId: 'cust-1', decision: 'verified'),
        isFalse,
      );
      expect(
        await ds.decideKyc(
            customerId: 'cust-1',
            decision: 'rejected',
            reason: 'Photo is unreadable.'),
        isFalse,
      );
    });

    test('rejects an invalid decision and a reason-less rejection', () async {
      final ds = AdminKycDataSource();
      expect(
        await ds.decideKyc(customerId: 'cust-1', decision: 'approved'),
        isFalse,
      );
      expect(
        await ds.decideKyc(customerId: 'cust-1', decision: 'rejected'),
        isFalse,
      );
      expect(
        await ds.decideKyc(
            customerId: 'cust-1', decision: 'rejected', reason: '   '),
        isFalse,
      );
    });
  });

  group('KYC review permission (decideKyc)', () {
    test('super admin and operations may review, support may not', () {
      expect(
          AdminPermissions.can('super_admin', AdminPermission.decideKyc),
          isTrue);
      expect(
          AdminPermissions.can('operations', AdminPermission.decideKyc),
          isTrue);
      expect(AdminPermissions.can('support', AdminPermission.decideKyc),
          isFalse);
      expect(AdminPermissions.can(null, AdminPermission.decideKyc), isFalse);
    });

    test('routes are the /admin/kyc-review pair', () {
      expect(RouteNames.adminKycReview, '/admin/kyc-review');
      expect(RouteNames.adminKycReviewDetail, '/admin/kyc-review/:customerId');
    });
  });

  group('kycReviewImageUrl', () {
    test('a full URL passes through, a bare key gets a signed URL', () {
      final client = CPanelStorageClient(
          baseUrl: 'https://example.com', apiSecretKey: 'test-secret');
      expect(
        kycReviewImageUrl('https://cdn.example.com/a.jpg', client, 'cust-1'),
        'https://cdn.example.com/a.jpg',
      );
      final signed = kycReviewImageUrl('kyc/cust-1/front.jpg', client, 'cust-1');
      expect(signed, startsWith('https://example.com/storage/media.php?key='));
      expect(signed, contains(Uri.encodeComponent('kyc/cust-1/front.jpg')));
      expect(kycReviewImageUrl('', client, 'cust-1'), '');
    });
  });

  group('AdminKycReviewView — queue', () {
    testWidgets('lists pending submissions newest first',
        (tester) async {
      final newer = submission(
          id: 'cust-new', submittedAt: DateTime(2026, 11, 14));
      final older = submission(
          id: 'cust-old',
          name: 'Sara Khan',
          cnic: '35202-7654321-1',
          submittedAt: DateTime(2026, 11, 12));
      // The view renders the queue in the order the data source
      // hands it (already newest-first — see sortNewestFirst).
      await tester.pumpWidget(wrap(AdminKycReviewView(
        loadQueue: () async => [newer, older],
        resolveAdminRole: () async => 'operations',
      )));
      await tester.pumpAndSettle();
      expect(find.text('KYC Review'), findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.text('Sara Khan'), findsOneWidget);
      expect(find.textContaining('35202-1234567-1'), findsOneWidget);
      final tiles =
          tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles.first.title, isA<Text>());
      expect((tiles.first.title as Text).data, 'Bilal Ahmed');
      expect((tiles.last.title as Text).data, 'Sara Khan');
    });

    testWidgets('shows the honest empty state when nothing is pending',
        (tester) async {
      await tester.pumpWidget(wrap(AdminKycReviewView(
        loadQueue: () async => [],
        resolveAdminRole: () async => 'super_admin',
      )));
      await tester.pumpAndSettle();
      expect(find.text('No pending KYC submissions'), findsOneWidget);
    });

    testWidgets('support sees the not-permitted state, queue never loads',
        (tester) async {
      var loaded = false;
      await tester.pumpWidget(wrap(AdminKycReviewView(
        loadQueue: () async {
          loaded = true;
          return [submission()];
        },
        resolveAdminRole: () async => 'support',
      )));
      await tester.pumpAndSettle();
      expect(
          find.text('Only super admins and operations can review KYC'),
          findsOneWidget);
      expect(find.text('Bilal Ahmed'), findsNothing);
      expect(loaded, isFalse);
    });
  });

  group('AdminKycReviewDetailView — review detail', () {
    Future<void> pumpDetail(
      WidgetTester tester, {
      required String role,
      String? qrCode,
      Future<bool> Function({
        required String customerId,
        required String decision,
        required String reason,
      })? decide,
      String Function(String key, String customerId)? resolveImageUrl,
    }) async {
      await tester.pumpWidget(wrap(AdminKycReviewDetailView(
        // Fresh state per pump: without a key the second pump reuses
        // the first pump's state and never re-loads.
        key: UniqueKey(),
        customerId: 'cust-1',
        loadSubmission: (_) async => submission(),
        resolveAdminRole: () async => role,
        loadQrCode: qrCode == null ? null : (_) async => qrCode,
        resolveImageUrl:
            resolveImageUrl ?? (_, __) => 'https://example.com/doc.jpg',
        decideKyc: decide,
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('shows documents, CNIC and license for a super admin',
        (tester) async {
      await pumpDetail(tester, role: 'super_admin', qrCode: '987654');
      expect(find.text('Bilal Ahmed'), findsOneWidget);
      expect(find.textContaining('35202-1234567-1'), findsOneWidget);
      expect(find.textContaining('LHR-12345'), findsOneWidget);
      expect(find.text('CNIC front'), findsOneWidget);
      expect(find.text('CNIC back'), findsOneWidget);
      expect(find.text('License front'), findsOneWidget);
      expect(find.text('License back'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('QR number is shown to a super admin only',
        (tester) async {
      await pumpDetail(tester, role: 'super_admin', qrCode: '987654');
      expect(find.textContaining('987654'), findsOneWidget);
      await pumpDetail(tester, role: 'operations', qrCode: '987654');
      expect(find.textContaining('987654'), findsNothing);
    });

    testWidgets('reject without a reason is refused, with a reason saves',
        (tester) async {
      String? seenDecision;
      String? seenReason;
      GoRouter routerFor() {
        return GoRouter(
          initialLocation: RouteNames.adminKycReviewDetail
              .replaceFirst(':customerId', 'cust-1'),
          routes: [
            GoRoute(
              path: RouteNames.adminKycReview,
              builder: (_, __) => AdminKycReviewView(
                loadQueue: () async => [],
                resolveAdminRole: () async => 'super_admin',
              ),
            ),
            GoRoute(
              path: RouteNames.adminKycReviewDetail,
              builder: (_, state) => AdminKycReviewDetailView(
                customerId: state.pathParameters['customerId'] ?? '',
                loadSubmission: (_) async => submission(),
                resolveAdminRole: () async => 'super_admin',
                loadQrCode: (_) async => '987654',
                resolveImageUrl: (_, __) => 'https://example.com/doc.jpg',
                decideKyc: ({
                  required String customerId,
                  required String decision,
                  required String reason,
                }) async {
                  seenDecision = decision;
                  seenReason = reason;
                  return true;
                },
              ),
            ),
          ],
        );
      }

      await tester.pumpWidget(MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routerFor(),
      ));
      await tester.pumpAndSettle();
      // The decisions sit below the fold at the default 800x600
      // viewport — scroll them into view before tapping.
      await tester.ensureVisible(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(
          find.text('A reason is required to reject — the customer sees it.'),
          findsOneWidget);
      expect(seenDecision, isNull);
      // The error SnackBar overlays the bottom of the screen where
      // the Reject button sits — let it expire before tapping again.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(
          find.byType(TextField), 'CNIC photo is unreadable.');
      await tester.ensureVisible(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(seenDecision, 'rejected');
      expect(seenReason, 'CNIC photo is unreadable.');
      expect(find.text('No pending KYC submissions'), findsOneWidget);
    });

    testWidgets('approve saves a verified decision and returns to the queue',
        (tester) async {
      String? seenDecision;
      await tester.pumpWidget(MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: RouteNames.adminKycReviewDetail
              .replaceFirst(':customerId', 'cust-1'),
          routes: [
            GoRoute(
              path: RouteNames.adminKycReview,
              builder: (_, __) => AdminKycReviewView(
                loadQueue: () async => [],
                resolveAdminRole: () async => 'operations',
              ),
            ),
            GoRoute(
              path: RouteNames.adminKycReviewDetail,
              builder: (_, state) => AdminKycReviewDetailView(
                customerId: state.pathParameters['customerId'] ?? '',
                loadSubmission: (_) async => submission(),
                resolveAdminRole: () async => 'operations',
                resolveImageUrl: (_, __) => 'https://example.com/doc.jpg',
                decideKyc: ({
                  required String customerId,
                  required String decision,
                  required String reason,
                }) async {
                  seenDecision = decision;
                  return true;
                },
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      // The decisions sit below the fold at the default 800x600
      // viewport — scroll the button into view before tapping.
      await tester.ensureVisible(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      // Phase 1 (1.1): approve asks first — the decision only
      // saves after the confirm dialog is accepted.
      expect(find.text('Approve this KYC submission?'), findsOneWidget);
      expect(seenDecision, isNull);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(seenDecision, 'verified');
      expect(find.text('No pending KYC submissions'), findsOneWidget);
    });

    testWidgets('approve cancelled at the confirm step saves nothing',
        (tester) async {
      String? seenDecision;
      await tester.pumpWidget(MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: RouteNames.adminKycReviewDetail
              .replaceFirst(':customerId', 'cust-1'),
          routes: [
            GoRoute(
              path: RouteNames.adminKycReview,
              builder: (_, __) => AdminKycReviewView(
                loadQueue: () async => [],
                resolveAdminRole: () async => 'operations',
              ),
            ),
            GoRoute(
              path: RouteNames.adminKycReviewDetail,
              builder: (_, state) => AdminKycReviewDetailView(
                customerId: state.pathParameters['customerId'] ?? '',
                loadSubmission: (_) async => submission(),
                resolveAdminRole: () async => 'operations',
                resolveImageUrl: (_, __) => 'https://example.com/doc.jpg',
                decideKyc: ({
                  required String customerId,
                  required String decision,
                  required String reason,
                }) async {
                  seenDecision = decision;
                  return true;
                },
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(find.text('Approve this KYC submission?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(seenDecision, isNull);
      expect(find.text('Bilal Ahmed'), findsOneWidget);
    });

    testWidgets('support sees the not-permitted state on the detail too',
        (tester) async {
      var loaded = false;
      await tester.pumpWidget(wrap(AdminKycReviewDetailView(
        customerId: 'cust-1',
        loadSubmission: (_) async {
          loaded = true;
          return submission();
        },
        resolveAdminRole: () async => 'support',
        resolveImageUrl: (_, __) => 'https://example.com/doc.jpg',
      )));
      await tester.pumpAndSettle();
      expect(
          find.text('Only super admins and operations can review KYC'),
          findsOneWidget);
      expect(loaded, isFalse);
    });
  });

  group('Online Customers — KYC Queue sub-tab and sidebar', () {
    testWidgets('shown when decideKyc allows it, hidden otherwise',
        (tester) async {
      await tester.pumpWidget(wrap(Scaffold(
          body: AdminSidebarNav(
        activeRoute: RouteNames.adminDashboard,
        onNavigate: (_) {},
        showApkDownload: false,
        showKycReview: true,
      ))));
      await tester.pumpAndSettle();
      expect(find.text('Online Customers'), findsOneWidget);
      expect(find.text('Approvals'), findsNothing);

      await tester.pumpWidget(wrap(Scaffold(
        body: Builder(
          builder: (context) => AdminSubTabBar(
            tabs: AdminSectionTabs.onlineCustomers(
              context,
              activeRoute: RouteNames.adminCustomers,
              canDecideKyc: true,
            ),
            onSelect: (_) {},
          ),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('KYC Queue'), findsOneWidget);

      await tester.pumpWidget(wrap(Scaffold(
        body: Builder(
          builder: (context) => AdminSubTabBar(
            tabs: AdminSectionTabs.onlineCustomers(
              context,
              activeRoute: RouteNames.adminCustomers,
              canDecideKyc: false,
            ),
            onSelect: (_) {},
          ),
        ),
      )));
      await tester.pumpAndSettle();
      expect(find.text('KYC Queue'), findsNothing);
    });
  });
}
