import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Owner Module Plan — Phase A (A1/A2/A3).
// Guards the routing work without needing Firebase: the mock owner flow
// view must stay deleted, the router must point at the real owner views,
// and the new routes/loaders must exist. If a future change reintroduces
// OwnerFlowView or drops a route, this test fails first.
void main() {
  group('Phase A — owner routes point at real views', () {
    test('OwnerFlowView is deleted and never referenced', () {
      expect(
        File('lib/features/owner/presentation/owner_flow_view.dart')
            .existsSync(),
        isFalse,
        reason: 'Phase A (A2): OwnerFlowView was deleted; do not re-add it.',
      );
      final router = File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(router, isNot(contains('OwnerFlowView')),
          reason: 'Phase A (A1): no owner route may point at OwnerFlowView.');
      expect(router, contains('OwnerDashboardView'));
      expect(router, contains('OwnerBookingRequestsView'));
      // Item 9 (O26–O30): the handover route now lands on the
      // 5-step wizard instead of the old single view.
      expect(router, contains('OwnerHandoverWizardView'));
      expect(router, contains('OwnerReturnSettlementView'));
      expect(router, contains('OwnerContractView'));
      expect(router, contains('OwnerCustomerRatingView'));
      expect(router, contains('OwnerCustomerScanView'));
      expect(router, contains('OwnerManualBookingView'));
      expect(router, contains('OwnerRateMatrixView'));
    });

    test('new owner routes exist in route_names.dart', () {
      final names =
          File('lib/core/routing/route_names.dart').readAsStringSync();
      const expected = <String>{
        'ownerRequestsDetail',
        'ownerManualBooking',
        'ownerPaymentProof',
        'ownerContract',
        'ownerRateCustomer',
        'ownerCustomerScan',
        'ownerRatesVehicle',
        'ownerAddVehicle',
        'ownerSubscription',
        'ownerWhatsappLogs',
      };
      for (final route in expected) {
        expect(names, contains(route),
            reason: 'Phase A (A1): route $route is missing from RouteNames.');
      }
    });

    test('phone-test routes exist: ownerAddCustomer and syncDetails', () {
      final names =
          File('lib/core/routing/route_names.dart').readAsStringSync();
      expect(names, contains("ownerAddCustomer = '/owner/customers/add'"),
          reason: 'Phone-test #18: the scan view Proceed target.');
      expect(names, contains("syncDetails = '/sync-details'"),
          reason: 'Phone-test #4: the failed-banner/details target.');
      final router =
          File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(router, contains('OwnerAddCustomerWizard'));
      expect(router, contains('SyncDetailsView'));
      // syncDetails is a top-level route (no tab bar), not a shell
      // branch route: it must be registered outside the shells.
      expect(router.indexOf('SyncDetailsView'),
          greaterThan(router.lastIndexOf('StatefulShellRoute.indexedStack')));
    });

    test('route loaders exist and stay under the 250-line view cap', () {
      final file = File(
        'lib/features/owner/presentation/widgets/owner_route_loaders.dart',
      );
      expect(file.existsSync(), isTrue,
          reason: 'Phase A (A1): owner_route_loaders.dart is missing.');
      final lines = file.readAsLinesSync().length;
      expect(lines, lessThanOrEqualTo(250),
          reason: 'Rulebook §2.2: loader file is $lines lines.');
      final content = file.readAsStringSync();
      expect(content, contains('BookingRouteLoader'));
      expect(content, contains('VehicleRouteLoader'));
      expect(content, contains('getBookingById'));
    });

    test('booking requests view has no demo fallback booking', () {
      final content = File(
        'lib/features/owner/presentation/views/owner_booking_requests_view.dart',
      ).readAsStringSync();
      expect(content, isNot(contains('RH-REQ-778')),
          reason:
              'Phase A (A1): the hardcoded demo request must not come back.');
      expect(content, contains('ownerRequestsDetail'),
          reason: 'Phase A (A1): tapping a request must open its detail.');
    });
  });
}
