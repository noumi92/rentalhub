import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_kyc_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_platform_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_shops_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/domain/report_series.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_dispute_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_kyc_review_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_ticket_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_list_card.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_report_charts.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_shell.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sort_menu.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sticky_action_bar.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_status_chip.dart';
import 'package:rentalhub/features/admin/presentation/widgets/customer_trust_breakdown.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_customer_list_tile.dart';
import 'package:rentalhub/features/blacklist/domain/entities/blacklist_entity.dart';
import 'package:rentalhub/features/bookings/data/models/booking_model.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/finance/data/models/finance_transfer_model.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Phase 4 — admin panel polish: the shared list card / status chip
// (4.1), Reports charts + trend (4.2), sort controls (4.3), sticky
// action bars + live-score-only trust (4.4).
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  BookingModel booking({
    required String id,
    required DateTime pickup,
    required int amount,
    String status = 'completed',
  }) {
    return BookingModel(
      bookingId: id,
      customerId: 'cust-1',
      shopId: 'shop-1',
      vehicleId: 'veh-1',
      packageType: 'daily',
      pickupTime: pickup,
      returnTime: pickup.add(const Duration(days: 1)),
      totalAmount: amount,
      remainingBalance: 0,
      status: status,
    );
  }

  FinanceTransferModel transfer({
    required DateTime at,
    required String kind,
    required int amount,
  }) {
    return FinanceTransferModel(
      transferId: 't-${at.millisecondsSinceEpoch}-$kind',
      shopId: 'shop-1',
      accountId: 'acc-1',
      kind: kind,
      category: 'other',
      amountPkr: amount,
      createdAt: at,
    );
  }

  group('4.1 — shared list card and status chip', () {
    test('tone mappings are preserved per list (and differ)', () {
      // 'paid' is info on bookings and has no equivalent on cars.
      expect(bookingStatusTone('paid'), AdminStatusTone.info);
      expect(bookingStatusTone('completed'), AdminStatusTone.success);
      expect(bookingStatusTone('disputed'), AdminStatusTone.warning);
      expect(bookingStatusTone('cancelled'), AdminStatusTone.danger);
      // Cars: 'pending' is neutral here, warning on shops.
      expect(carReviewStatusTone('pending'), AdminStatusTone.neutral);
      expect(carReviewStatusTone('approved'), AdminStatusTone.success);
      expect(carReviewStatusTone('hidden'), AdminStatusTone.warning);
      expect(carReviewStatusTone('rejected'), AdminStatusTone.danger);
      expect(
          shopStatusTone(suspended: false, verificationStatus: 'pending'),
          AdminStatusTone.warning);
      expect(
          shopStatusTone(suspended: false, verificationStatus: 'approved'),
          AdminStatusTone.success);
      expect(shopStatusTone(suspended: true, verificationStatus: 'approved'),
          AdminStatusTone.danger);
    });

    testWidgets('AdminListCard renders title, subtitle and trailing',
        (tester) async {
      await tester.pumpWidget(wrap(AdminListCard(
        icon: Icons.store_rounded,
        title: 'Metro Motors',
        subtitle: 'Lahore • pro',
        trailing: AdminStatusChip.bookingStatus('paid'),
        onTap: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Metro Motors'), findsOneWidget);
      expect(find.text('Lahore • pro'), findsOneWidget);
      expect(find.byType(AdminStatusChip), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('AdminFactTile renders label over value', (tester) async {
      await tester.pumpWidget(wrap(const AdminFactTile(
        label: 'Plan',
        value: 'pro',
      )));
      await tester.pumpAndSettle();
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('pro'), findsOneWidget);
    });
  });

  group('4.2 — Reports series and trend', () {
    test('daily buckets cover quiet days and count booked value only',
        () {
      final series = buildReportSeries(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 3),
        bookings: [
          booking(
              id: 'b1',
              pickup: DateTime(2026, 10, 1, 10),
              amount: 10000,
              status: 'completed'),
          booking(
              id: 'b2',
              pickup: DateTime(2026, 10, 1, 12),
              amount: 5000,
              status: 'cancelled'),
          booking(
              id: 'b3',
              pickup: DateTime(2026, 10, 3, 9),
              amount: 7000,
              status: 'paid'),
        ],
        transfers: [
          transfer(at: DateTime(2026, 10, 2), kind: 'income', amount: 3000),
          transfer(at: DateTime(2026, 10, 2), kind: 'expense', amount: 1200),
        ],
      );
      expect(series.length, 3);
      expect(series[0].bookings, 2);
      expect(series[0].revenue, 10000);
      expect(series[1].bookings, 0);
      expect(series[1].income, 3000);
      expect(series[1].expense, 1200);
      expect(series[2].bookings, 1);
      expect(series[2].revenue, 7000);
    });

    test('ranges over 62 days bucket monthly', () {
      final series = buildReportSeries(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 12, 31),
        bookings: [
          booking(
              id: 'b1',
              pickup: DateTime(2026, 3, 5),
              amount: 1000,
              status: 'completed'),
        ],
        transfers: const [],
      );
      expect(series.length, 12);
      expect(series[2].bookings, 1);
      expect(series[2].label, 'Mar 2026');
    });

    test('trendPercent handles a zero previous period', () {
      expect(trendPercent(current: 0, previous: 0), isNull);
      expect(trendPercent(current: 5, previous: 0), 100.0);
      expect(trendPercent(current: 15, previous: 10), 50.0);
      expect(trendPercent(current: 5, previous: 10), -50.0);
    });

    testWidgets('charts render with data and an empty state without',
        (tester) async {
      final report = AdminReport(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 3),
        series: buildReportSeries(
          from: DateTime(2026, 10, 1),
          to: DateTime(2026, 10, 3),
          bookings: [
            booking(
                id: 'b1',
                pickup: DateTime(2026, 10, 1, 10),
                amount: 10000),
          ],
          transfers: const [],
        ),
        totalBookings: 1,
        completedBookings: 1,
        bookingRevenue: 10000,
        bookingsByCity: const {'Lahore': 1},
        topShops: const [],
        financeIncome: 0,
        financeExpense: 0,
        incomeByCategory: const {},
        expenseByCategory: const {},
        newCustomers: 0,
        disputesOpen: 0,
        disputesResolved: 0,
      );
      await tester.pumpWidget(wrap(AdminReportCharts(report: report)));
      await tester.pumpAndSettle();
      expect(find.text('Bookings over time'), findsOneWidget);
      expect(find.text('Finance over time'), findsOneWidget);

      final empty = AdminReport(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 3),
        totalBookings: 0,
        completedBookings: 0,
        bookingRevenue: 0,
        bookingsByCity: {},
        topShops: [],
        financeIncome: 0,
        financeExpense: 0,
        incomeByCategory: {},
        expenseByCategory: {},
        newCustomers: 0,
        disputesOpen: 0,
        disputesResolved: 0,
      );
      await tester.pumpWidget(wrap(AdminReportCharts(report: empty)));
      await tester.pumpAndSettle();
      expect(find.text('No data in this range to chart.'), findsOneWidget);
    });

    testWidgets('trend line reports no previous data', (tester) async {
      // 0 vs 0 has no change to report (trendPercent returns
      // null); a non-zero current against a zero previous is +100%.
      await tester.pumpWidget(wrap(const AdminReportTrend(
        label: 'Bookings',
        current: 0,
        previous: 0,
      )));
      await tester.pumpAndSettle();
      expect(find.textContaining('no previous data'), findsOneWidget);
    });
  });

  group('4.3 — sort helpers', () {
    test('shops sort by name and by status (suspended first)', () {
      ShopModel shop(String name, String status, bool suspended) {
        return ShopModel(
          shopId: name,
          ownerId: 'o1',
          shopName: name,
          phoneNumber: '0300',
          address: 'a',
          city: 'Lahore',
          geoLocation: const GeoPointEntity(31.5, 74.3),
          bankAccounts: const [],
          verificationStatus: status,
          plan: 'free',
          suspended: suspended,
        );
      }

      final shops = [
        shop('Zebra', 'approved', false),
        shop('Alpha', 'pending', false),
        shop('Metro', 'approved', true),
      ];
      expect(
          AdminShopsDataSource.sortShops(shops, 'nameDesc')
              .map((s) => s.shopName)
              .toList(),
          ['Zebra', 'Metro', 'Alpha']);
      expect(
          AdminShopsDataSource.sortShops(shops, 'statusAsc')
              .map((s) => s.shopName)
              .toList(),
          ['Metro', 'Alpha', 'Zebra']);
    });

    test('bookings sort by amount and by date', () {
      final bookings = [
        booking(id: 'b1', pickup: DateTime(2026, 10, 2), amount: 1000),
        booking(id: 'b2', pickup: DateTime(2026, 10, 1), amount: 9000),
      ];
      expect(
          AdminPlatformDataSource.sortBookings(bookings, 'amountHigh')
              .map((b) => b.bookingId)
              .toList(),
          ['b2', 'b1']);
      expect(
          AdminPlatformDataSource.sortBookings(bookings, 'dateOldest')
              .map((b) => b.bookingId)
              .toList(),
          ['b2', 'b1']);
    });

    test('tickets, disputes, KYC, blacklist, audit log and announcements sort',
        () {
      final tickets = [
        SupportTicket(
            id: 't1',
            customerId: 'c1',
            message: 'm1',
            status: 'open',
            priority: 'low',
            createdAt: DateTime(2026, 10, 2)),
        SupportTicket(
            id: 't2',
            customerId: 'c2',
            message: 'm2',
            status: 'closed',
            priority: 'high',
            createdAt: DateTime(2026, 10, 1)),
      ];
      expect(
          AdminSupportDataSource.sortTickets(tickets, 'statusAsc')
              .map((t) => t.id)
              .toList(),
          ['t2', 't1']);
      expect(
          AdminSupportDataSource.sortTickets(tickets, 'dateOldest')
              .map((t) => t.id)
              .toList(),
          ['t2', 't1']);

      final disputes = [
        DisputeRecord(
            id: 'd1',
            bookingId: 'b1',
            category: 'damage',
            description: 'x',
            status: 'resolved',
            createdAt: DateTime(2026, 10, 2)),
        DisputeRecord(
            id: 'd2',
            bookingId: 'b2',
            category: 'late',
            description: 'y',
            status: 'open',
            createdAt: DateTime(2026, 10, 1)),
      ];
      expect(
          AdminPlatformDataSource.sortDisputes(disputes, 'statusAsc')
              .map((d) => d.id)
              .toList(),
          ['d2', 'd1']);

      final queue = [
        KycReviewSubmission(
            customerId: 'c2',
            customerName: 'Zara',
            cnicNumber: '1',
            cnicFrontKey: '',
            cnicBackKey: '',
            licenseKey: '',
            licenseBackKey: '',
            licenseNumber: '',
            licenseExpiry: '',
            submittedAt: DateTime(2026, 10, 2)),
        KycReviewSubmission(
            customerId: 'c1',
            customerName: 'Ali',
            cnicNumber: '2',
            cnicFrontKey: '',
            cnicBackKey: '',
            licenseKey: '',
            licenseBackKey: '',
            licenseNumber: '',
            licenseExpiry: '',
            submittedAt: DateTime(2026, 10, 1)),
      ];
      expect(
          AdminKycDataSource.sortKycSubmissions(queue, 'nameAsc')
              .map((s) => s.customerName)
              .toList(),
          ['Ali', 'Zara']);

      final cases = [
        AdminBlacklistRecord(
            entity: const BlacklistEntity(
                blacklistId: 'bl1',
                reportedByShopId: 's1',
                cnicNumber: '1',
                phoneNumber: '0300',
                reasonCategory: 'fraud',
                description: 'd',
                isActive: false,
                reportedAt: null),
            appealStatus: 'none',
            appealReason: ''),
        AdminBlacklistRecord(
            entity: BlacklistEntity(
                blacklistId: 'bl2',
                reportedByShopId: 's1',
                cnicNumber: '2',
                phoneNumber: '0300',
                reasonCategory: 'fraud',
                description: 'd',
                isActive: true,
                reportedAt: DateTime(2026, 10, 1)),
            appealStatus: 'none',
            appealReason: ''),
      ];
      expect(
          AdminPeopleDataSource.sortBlacklistRecords(cases, 'statusAsc')
              .map((r) => r.entity.blacklistId)
              .toList(),
          ['bl2', 'bl1']);

      final logs = [
        AuditLogEntry(
            id: 'a1',
            type: 't',
            action: 'zebra_action',
            actorEmail: 'a@x.pk',
            targetType: 'shop',
            targetId: 's1',
            detail: '',
            createdAt: DateTime(2026, 10, 2)),
        AuditLogEntry(
            id: 'a2',
            type: 't',
            action: 'alpha_action',
            actorEmail: 'a@x.pk',
            targetType: 'shop',
            targetId: 's1',
            detail: '',
            createdAt: DateTime(2026, 10, 1)),
      ];
      expect(
          AdminRemoteDataSource.sortAuditLogs(logs, 'actionAsc')
              .map((e) => e.id)
              .toList(),
          ['a2', 'a1']);

      final reviews = [
        AdminReview.fromMap('r1', {
          'shopRating': 2,
          'vehicleRating': 2,
          'moderationStatus': 'visible',
        }),
        AdminReview.fromMap('r2', {
          'shopRating': 5,
          'vehicleRating': 5,
          'moderationStatus': 'visible',
        }),
      ];
      expect(
          AdminPlatformDataSource.sortReviews(reviews, 'ratingHigh')
              .map((r) => r.id)
              .toList(),
          ['r2', 'r1']);

      final rows = [
        AdminCustomerRow(
            customer: CustomerModel(
                customerId: 'c2',
                shopId: 's1',
                name: 'Zara',
                phone: '0300',
                createdAt: DateTime(2026, 10, 2)),
            storedTrustScore: 4.0,
            isBlacklisted: false,
            watchlisted: false),
        AdminCustomerRow(
            customer: CustomerModel(
                customerId: 'c1',
                shopId: 's1',
                name: 'Ali',
                phone: '0300',
                createdAt: DateTime(2026, 10, 1)),
            storedTrustScore: null,
            isBlacklisted: false,
            watchlisted: false),
      ];
      expect(
          AdminPeopleDataSource.sortCustomerRows(rows, 'nameAsc')
              .map((r) => r.customer.name)
              .toList(),
          ['Ali', 'Zara']);
      expect(
          AdminPeopleDataSource.sortCustomerRows(rows, 'dateNewest')
              .map((r) => r.customer.name)
              .toList(),
          ['Zara', 'Ali']);
    });

    testWidgets('AdminSortMenu shows its options', (tester) async {
      var selected = 'dateNewest';
      await tester.pumpWidget(wrap(AdminSortMenu(
        options: const [
          AdminSortOption(id: 'dateNewest', label: 'Newest first'),
          AdminSortOption(id: 'dateOldest', label: 'Oldest first'),
        ],
        selectedId: selected,
        onSelected: (value) => selected = value,
      )));
      await tester.tap(find.byIcon(Icons.sort_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Newest first'), findsWidgets);
      expect(find.text('Oldest first'), findsOneWidget);
      await tester.tap(find.text('Oldest first'));
      await tester.pumpAndSettle();
      expect(selected, 'dateOldest');
    });
  });

  group('4.4a — sticky action bars', () {
    testWidgets('AdminShell renders a supplied bottom bar',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminShell(
          activeRoute: '/admin/shops',
          title: 'Shop',
          subtitle: 'Detail',
          bottomBar: FilledButton(
            onPressed: () {},
            child: const Text('Suspend shop'),
          ),
          child: const Text('body'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(AdminStickyActionBar), findsOneWidget);
      expect(find.text('Suspend shop'), findsOneWidget);
    });

    testWidgets('dispute detail puts Save in the sticky bar',
        (tester) async {
      final dispute = DisputeRecord(
        id: 'd1',
        bookingId: 'b1',
        category: 'damage',
        description: 'Scratched bumper',
        status: 'open',
        createdAt: DateTime(2026, 11, 20),
      );
      await tester.pumpWidget(wrap(AdminDisputeDetailView(
        key: UniqueKey(),
        disputeId: 'd1',
        loadDispute: (_) async => dispute,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(AdminStickyActionBar), findsOneWidget);
      // One Save only — the panel's own button is hidden on the
      // detail route.
      expect(find.text('Save decision'), findsOneWidget);
    });

    testWidgets('ticket detail puts Close / Escalate in the sticky bar',
        (tester) async {
      final ticket = SupportTicket(
        id: 't1',
        customerId: 'c1',
        message: 'My booking is stuck',
        status: 'open',
        priority: 'high',
        createdAt: DateTime(2026, 11, 20),
      );
      await tester.pumpWidget(wrap(AdminTicketDetailView(
        key: UniqueKey(),
        ticketId: 't1',
        loadTicket: (_) async => ticket,
      )));
      await tester.pumpAndSettle();
      expect(find.byType(AdminStickyActionBar), findsOneWidget);
      expect(find.text('Close ticket'), findsOneWidget);
      expect(find.text('Escalate'), findsOneWidget);
    });

    testWidgets('KYC detail puts Approve / Reject in the sticky bar only',
        (tester) async {
      await tester.pumpWidget(wrap(AdminKycReviewDetailView(
        key: UniqueKey(),
        customerId: 'cust-1',
        loadSubmission: (_) async => KycReviewSubmission(
          customerId: 'cust-1',
          customerName: 'Bilal Ahmed',
          cnicNumber: '35202-1234567-1',
          cnicFrontKey: 'kyc/cust-1/cnic-front.jpg',
          cnicBackKey: 'kyc/cust-1/cnic-back.jpg',
          licenseKey: 'kyc/cust-1/license.jpg',
          licenseBackKey: 'kyc/cust-1/license-back.jpg',
          licenseNumber: 'LHR-12345',
          licenseExpiry: '2030-01-01',
          submittedAt: DateTime(2026, 11, 20),
        ),
        resolveAdminRole: () async => 'super_admin',
        loadQrCode: (_) async => null,
        resolveImageUrl: (_, __) => 'https://example.com/doc.jpg',
      )));
      await tester.pumpAndSettle();
      expect(find.byType(AdminStickyActionBar), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });
  });

  group('4.4b — live-score-only trust display', () {
    testWidgets('breakdown shows the live score and no stored score',
        (tester) async {
      const breakdown = TrustScoreBreakdown(
        base: 2.5,
        kyc: 1.0,
        trips: 0.5,
        ratings: 0.0,
        punctuality: 0.0,
        conduct: 0.0,
        total: 4.0,
      );
      await tester.pumpWidget(wrap(const CustomerTrustBreakdown(
        breakdown: breakdown,
        completedTrips: 3,
        meanOwnerRating: null,
        kycStatus: 'verified',
      )));
      await tester.pumpAndSettle();
      expect(find.text('4.0 / 5.0'), findsOneWidget);
      expect(find.textContaining('Previously stored'), findsNothing);
      expect(find.textContaining('Stored trust'), findsNothing);
    });

    testWidgets('customer list tile never shows the stored score',
        (tester) async {
      final row = AdminCustomerRow(
        customer: CustomerModel(
          customerId: 'c1',
          shopId: 's1',
          name: 'Ali Khan',
          phone: '03001234567',
          cnic: '35202-1234567-1',
          createdAt: DateTime(2026, 10, 1),
        ),
        storedTrustScore: 5.0,
        isBlacklisted: false,
        watchlisted: false,
      );
      await tester.pumpWidget(wrap(AdminCustomerListTile(row: row)));
      await tester.pumpAndSettle();
      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.textContaining('Stored trust'), findsNothing);
      expect(find.textContaining('5.0'), findsNothing);
    });
  });
}
