// Item 5 (2026-11-21) — Customers tab: fleet-style filter bar
// (counts, 14sp labels, horizontal scroll, alert segments hidden
// at zero) + Add Customer moved from the FAB into the app bar pill.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/core/widgets/minimal_app_bar.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_customers_list_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_add_pill.dart';
import 'package:rentalhub/features/owner/presentation/widgets/customer_list_filter_chips.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  Widget wrapChips({
    CustomerListFilter selected = CustomerListFilter.all,
    int all = 4,
    int regular = 1,
    int isNew = 3,
    int blacklisted = 1,
    int withDues = 1,
    int pendingApproval = 1,
    int blocked = 1,
    ValueChanged<CustomerListFilter>? onSelected,
  }) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomerListFilterChips(
            selected: selected,
            allCount: all,
            regularCount: regular,
            newCount: isNew,
            blacklistedCount: blacklisted,
            withDuesCount: withDues,
            pendingApprovalCount: pendingApproval,
            blockedCount: blocked,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      );

  group('CustomerListFilterChips — fleet-style bar', () {
    testWidgets('segments carry counts at full 14sp size',
        (tester) async {
      await tester.pumpWidget(wrapChips());
      await tester.pumpAndSettle();
      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Regular (1)'), findsOneWidget);
      expect(find.text('New (3)'), findsOneWidget);
      expect(find.text('Blacklisted (1)'), findsOneWidget);
      expect(find.text('With Dues (1)'), findsOneWidget);
      expect(find.text('Pending review (1)'), findsOneWidget);
      expect(find.text('Blocked (1)'), findsOneWidget);
      // The old single Flagged segment is gone.
      expect(find.text('Flagged'), findsNothing);
      // Fleet bar spec: 14sp labels, set on the Text itself.
      final label =
          tester.widget<Text>(find.text('All (4)'));
      expect(label.style?.fontSize, 14);
      // The bar scrolls horizontally instead of shrinking.
      final scroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView));
      expect(scroll.scrollDirection, Axis.horizontal);
    });

    testWidgets('zero-count alert segments hide until they have rows',
        (tester) async {
      await tester.pumpWidget(wrapChips(
          blacklisted: 0, withDues: 0, pendingApproval: 0, blocked: 0));
      await tester.pumpAndSettle();
      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Regular (1)'), findsOneWidget);
      expect(find.text('New (3)'), findsOneWidget);
      expect(find.textContaining('Blacklisted ('), findsNothing);
      expect(find.textContaining('With Dues ('), findsNothing);
      expect(find.textContaining('Pending review ('), findsNothing);
      expect(find.textContaining('Blocked ('), findsNothing);
    });

    testWidgets('a selected zero-count segment stays visible',
        (tester) async {
      await tester.pumpWidget(wrapChips(
          selected: CustomerListFilter.blacklisted, blacklisted: 0));
      await tester.pumpAndSettle();
      expect(find.text('Blacklisted (0)'), findsOneWidget);
    });

    testWidgets('tapping a chip reports its filter', (tester) async {
      CustomerListFilter? tapped;
      await tester.pumpWidget(wrapChips(
          onSelected: (f) => tapped = f));
      await tester.pumpAndSettle();
      // The six counted chips are wider than the 800px test
      // surface — scroll the tapped chip into view first.
      await tester.ensureVisible(find.text('With Dues (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('With Dues (1)'));
      expect(tapped, CustomerListFilter.withDues);
      await tester.ensureVisible(find.text('Pending review (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending review (1)'));
      expect(tapped, CustomerListFilter.pendingApproval);
      await tester.ensureVisible(find.text('Blocked (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blocked (1)'));
      expect(tapped, CustomerListFilter.blocked);
    });
  });

  group('OwnerCustomersListView — filters + Add Customer pill', () {
    Future<void> seedShop(String shopId) async {
      final bookingDs = di.sl<BookingRemoteDataSource>();
      Future<void> seedBooking({
        required String customerId,
        required String name,
        required String phone,
        required String cnic,
        required DateTime pickup,
      }) async {
        await bookingDs.createBookingRequest(
          customerId: customerId,
          shopId: shopId,
          vehicleId: 'veh-1',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: pickup,
          returnTime: pickup.add(const Duration(days: 1)),
          totalAmount: 9000,
          advanceRequired: 1000,
          customerName: name,
          customerPhone: phone,
          customerCnic: cnic,
        );
      }

      // Regular: 2 rentals.
      await seedBooking(customerId: 'cust-f5-reg', name: 'Regular Rana', phone: '0300-5550001', cnic: '35202-5550001-1', pickup: DateTime(2026, 11, 3, 9));
      await seedBooking(customerId: 'cust-f5-reg', name: 'Regular Rana', phone: '0300-5550001', cnic: '35202-5550001-1', pickup: DateTime(2026, 11, 4, 9));
      // Blacklisted: 1 rental, CNIC reported to the blacklist.
      await seedBooking(customerId: 'cust-f5-bl', name: 'Blacklisted Bob', phone: '0300-5550002', cnic: '35202-5550002-2', pickup: DateTime(2026, 11, 5, 9));
      await di.sl<BlacklistRemoteDataSource>().reportCustomerToBlacklist(
            reportedByShopId: shopId,
            cnicNumber: '35202-5550002-2',
            phoneNumber: '0300-5550002',
            reasonCategory: 'Default & Car Impoundment',
            description: 'Test report.',
          );
      // With dues: 1 rental moved to approved with the full balance
      // still outstanding.
      final due = await bookingDs.createBookingRequest(
        customerId: 'cust-f5-due',
        shopId: shopId,
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 6, 9),
        returnTime: DateTime(2026, 11, 7, 9),
        totalAmount: 12000,
        advanceRequired: 1000,
        customerName: 'Due Daniyal',
        customerPhone: '0300-5550003',
        customerCnic: '35202-5550003-3',
      );
      await bookingDs.updateBookingStatus(
          bookingId: due.bookingId, status: 'approved');
      // Pending approval: saved ONLINE record, no bookings yet —
      // the default approvalStatus is 'pending'. (Walk-in records
      // also sit at 'pending' but never match Pending Approval —
      // approve/reject was removed for walk-ins — so the seed here
      // is online, like the real pending queue.)
      await di.sl<CustomerRemoteDataSource>().upsertCustomer(CustomerEntity(
            customerId: 'cust-f5-pa',
            shopId: shopId,
            name: 'Pending Paula',
            phone: '0300-5550004',
            cnic: '35202-5550004-4',
            source: 'online',
            createdAt: DateTime(2026, 11, 6),
          ));
    }

    Future<void> pumpList(WidgetTester tester, String shopId) async {
      // Tall viewport (repo pattern): four rows sit below the fold
      // at the default 600px height and ListView.builder never
      // builds them.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OwnerCustomersListView(shopId: shopId),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('each filter isolates its rows', (tester) async {
      const shopId = 'shop-filt-5';
      await seedShop(shopId);
      await pumpList(tester, shopId);

      expect(find.text('All (4)'), findsOneWidget);
      expect(find.text('Regular (1)'), findsOneWidget);
      expect(find.text('New (3)'), findsOneWidget);
      expect(find.text('Blacklisted (1)'), findsOneWidget);
      expect(find.text('With Dues (1)'), findsOneWidget);
      expect(find.text('Pending review (1)'), findsOneWidget);
      // Nobody here is blocked, so the Blocked segment hides.
      expect(find.textContaining('Blocked ('), findsNothing);
      expect(find.text('Flagged'), findsNothing);

      // The six counted chips are wider than the 800px test
      // surface — scroll each tapped chip into view first.
      Future<void> tapChip(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tapChip('Blacklisted (1)');
      expect(find.text('Blacklisted Bob'), findsOneWidget);
      expect(find.text('Regular Rana'), findsNothing);
      expect(find.text('Due Daniyal'), findsNothing);
      expect(find.text('Pending Paula'), findsNothing);

      await tapChip('With Dues (1)');
      expect(find.text('Due Daniyal'), findsOneWidget);
      expect(find.text('Blacklisted Bob'), findsNothing);
      expect(find.text('Regular Rana'), findsNothing);
      expect(find.text('Pending Paula'), findsNothing);

      await tapChip('Pending review (1)');
      expect(find.text('Pending Paula'), findsOneWidget);
      expect(find.text('Blacklisted Bob'), findsNothing);
      expect(find.text('Due Daniyal'), findsNothing);
      expect(find.text('Regular Rana'), findsNothing);

      await tapChip('All (4)');
      expect(find.text('Regular Rana'), findsOneWidget);
      expect(find.text('Blacklisted Bob'), findsOneWidget);
      expect(find.text('Due Daniyal'), findsOneWidget);
      expect(find.text('Pending Paula'), findsOneWidget);
    });

    testWidgets('Add Customer is an app-bar pill, not a FAB',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/owner/customers',
        routes: [
          GoRoute(
            path: '/owner/customers',
            builder: (context, state) =>
                const OwnerCustomersListView(shopId: 'shop-filt-5b'),
          ),
          GoRoute(
            path: '/owner/customers/add',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('add-stub')),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      // The pill keeps the old FAB's key so tests keep addressing
      // it; the FAB itself is gone.
      expect(find.byKey(const Key('customers-action-add')),
          findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Add Customer'), findsOneWidget);

      await tester.tap(find.byKey(const Key('customers-action-add')));
      await tester.pumpAndSettle();
      expect(find.text('add-stub'), findsOneWidget);
    });

    testWidgets('app bar with pill fits at 360px and 200% text scale',
        (tester) async {
      // Scoped to the app bar (this item's change): the list rows
      // themselves overflow at 360px in the test font — pre-existing
      // (audit15_leftovers drains the same overflow for the expanded
      // row) — and the shared in-memory pending queue leaks other
      // tests' bookings into any shop, so a full-view 360px pump
      // cannot isolate the bar.
      for (final scale in [1.0, 2.0]) {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(360, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return MinimalAppBar(
                            title: l10n.customersManagementTitle,
                            subtitle: l10n.customersCount(4),
                            actions: [
                              CustomerAddPill(onPressed: () {}),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: l10n.customersScanCnic,
                                icon: const Icon(
                                    Icons.document_scanner_rounded,
                                    color: Colors.white),
                                onPressed: () {},
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('customers-action-add')),
            findsOneWidget);
        expect(find.text('Add Customer'), findsOneWidget);
        // E3: the unclamped pill overflowed the app-bar Row by 26px
        // at 200% (ui_accessibility_test 'Owner Customers at 200%').
        expect(tester.takeException(), isNull,
            reason: 'app bar must not overflow at ${scale}x text scale');
      }
    });
  });
}
