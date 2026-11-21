import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_disputes_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('Owner disputes inbox — data layer', () {
    test('filed disputes are listed for their shop only', () async {
      final ds = DisputeRemoteDataSource();
      await ds.fileDispute(
        bookingId: 'RH-DSP-1',
        customerId: 'cust-1',
        category: 'Late return',
        description: 'Car came back late.',
        shopId: 'shop-dsp',
      );
      await ds.fileDispute(
        bookingId: 'RH-DSP-2',
        customerId: 'cust-2',
        category: 'Damage',
        description: 'Scratch not noted at handover.',
        shopId: 'shop-other',
      );
      final mine = await ds.getShopDisputes('shop-dsp');
      expect(mine.length, 1);
      expect(mine.first.bookingId, 'RH-DSP-1');
      expect(mine.first.status, 'open');
      expect(await ds.getShopDisputes('shop-other'),
          hasLength(1));
    });

    test('status moves open -> in_review -> resolved', () async {
      final ds = DisputeRemoteDataSource();
      final filed = await ds.fileDispute(
        bookingId: 'RH-DSP-3',
        customerId: 'cust-1',
        category: 'Refund',
        description: 'Deposit not returned.',
        shopId: 'shop-dsp',
      );
      await ds.updateDisputeStatus(filed.id, 'in_review');
      var list = await ds.getShopDisputes('shop-dsp');
      expect(list.firstWhere((d) => d.id == filed.id).status, 'in_review');
      await ds.updateDisputeStatus(filed.id, 'resolved');
      list = await ds.getShopDisputes('shop-dsp');
      expect(list.firstWhere((d) => d.id == filed.id).status, 'resolved');
    });
  });

  group('Owner disputes inbox — view', () {
    testWidgets('shows the shop dispute and resolves it from the sheet',
        (tester) async {
      final ds = sl<DisputeRemoteDataSource>();
      await ds.fileDispute(
        bookingId: 'RH-DSP-VIEW',
        customerId: 'cust-9',
        category: 'Late return',
        description: 'Car came back two hours late.',
        shopId: 'shop-1',
      );
      // Item 2 navigate-back: resolving from the centre leaves it
      // for All Bookings, so the view needs a router — and the
      // status change itself is verified on the data source below
      // instead of on the (now unmounted) centre.
      final router = GoRouter(
        initialLocation: '/owner/disputes',
        routes: [
          GoRoute(
            path: '/owner/disputes',
            builder: (_, __) => const OwnerDisputesView(shopId: 'shop-1'),
          ),
          GoRoute(
            path: '/owner/requests',
            builder: (_, __) => const Scaffold(body: Text('requests')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Late return'), findsOneWidget);
      expect(find.textContaining('RH-DSP-VIEW'), findsOneWidget);

      await tester.tap(find.text('Late return'));
      await tester.pumpAndSettle();
      expect(find.text('Car came back two hours late.'), findsOneWidget);

      await tester.tap(find.text('Mark in review'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(),
          '/owner/requests?filter=all');
      final after =
          await ds.getShopDisputes('shop-1');
      expect(
          after
              .firstWhere((d) => d.bookingId == 'RH-DSP-VIEW')
              .status,
          'in_review');
    });
  });
}
