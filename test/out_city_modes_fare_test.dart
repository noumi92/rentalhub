import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/bookings/presentation/widgets/package_tier_list.dart';
import 'package:rentalhub/features/fleet/domain/entities/fixed_route_entity.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';

// 09b §2 out-of-city modes: Per day / Per km / Fixed route pricing
// in the fare path — ManualBookingPackageSelector.unitFor/totalFor
// and PackageTierList.optionsFor.
//
// THE PER-KM ESTIMATE RULE: a per-km trip has no flat package price.
// The fare is an ESTIMATE — days × outOfCityKmPerDay (stored,
// default 300) × per-km rate — and the final total settles on the
// actual km at return. A single package unit estimates its own
// duration: rate × km/day × hours/24 (24h = one full allowance,
// 6h = a quarter of it). A fixed route is one flat trip price plus
// the driver surcharge per day — the route price is NEVER
// multiplied by days.
void main() {
  const packages = [
    VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1000, kmIncluded: 15),
    VehiclePackageEntity(label: '6h', hours: 6, pricePkr: 4000, kmIncluded: 80),
    VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 7000, kmIncluded: 250),
    VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 42000, kmIncluded: 1750),
    VehiclePackageEntity(label: 'Monthly', hours: 720, pricePkr: 168000, kmIncluded: 7500),
  ];

  VehicleEntity vehicleFor({String? outCityMode, int? outCityPerKmPkr, String? outCityFixedRouteId}) {
    return VehicleEntity(
      vehicleId: 'veh-modes',
      shopId: 'shop-1',
      make: 'Toyota',
      model: 'Corolla GLi',
      year: 2022,
      plateNumber: 'LEA-22-7000',
      rates: const VehicleRatesEntity(daily24: 7000, outOfCityDaily: 9500),
      withDriverSurchargePkr: 1500,
      extraKmPkr: 25,
      outOfCityKmPerDay: 350,
      packages: packages,
      outCityMode: outCityMode,
      outCityPerKmPkr: outCityPerKmPkr,
      outCityFixedRouteId: outCityFixedRouteId,
    );
  }

  const route = FixedRouteEntity(
    routeId: 'route-lhr-isb',
    shopId: 'shop-1',
    originCity: 'Lahore',
    destinationCity: 'Islamabad',
    distanceKm: 300,
    fixedPricePkr: 18000,
  );

  final pickup = DateTime(2026, 10, 26, 10);
  final threeDays = DateTime(2026, 10, 29, 10);
  final twoDays = DateTime(2026, 10, 28, 10);

  VehiclePackageEntity pkg(VehicleEntity v, String label) =>
      v.packages.firstWhere((p) => p.label == label);

  group('unitFor / totalFor — per-day mode is unchanged', () {
    test('out-of-city scales the package by the out-city ratio', () {
      final v = vehicleFor();
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true),
        9500,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true, pickup: pickup, returnTime: twoDays),
        19000,
      );
    });

    test('in-city ignores the mode fields', () {
      final v = vehicleFor(outCityMode: 'perKm', outCityPerKmPkr: 30);
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false),
        7000,
      );
    });
  });

  group('unitFor / totalFor — per-km mode (estimate rule)', () {
    test('a 24h unit estimates one full km allowance', () {
      final v = vehicleFor(outCityMode: 'perKm', outCityPerKmPkr: 30);
      // 350 km/day × Rs. 30/km.
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true),
        10500,
      );
    });

    test('hourly and weekly units prorate the allowance', () {
      final v = vehicleFor(outCityMode: 'perKm', outCityPerKmPkr: 30);
      // 6h: 350 × 6/24 = 87.5 km × 30 = 2625.
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '6h'), isWithDriver: false, isOutOfCity: true),
        2625,
      );
      // Weekly: 7 × 350 km × 30.
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, 'Weekly'), isWithDriver: false, isOutOfCity: true),
        73500,
      );
    });

    test('total is days × km/day × rate, plus driver per day', () {
      final v = vehicleFor(outCityMode: 'perKm', outCityPerKmPkr: 30);
      expect(
        ManualBookingPackageSelector.totalFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true, pickup: pickup, returnTime: threeDays),
        31500,
      );
      // (10500 + 1500 driver) × 2 days + 1 night × 2000 stay.
      expect(
        ManualBookingPackageSelector.totalFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: true, isOutOfCity: true, pickup: pickup, returnTime: twoDays, driverRatePerDayPkr: 1500),
        26000,
      );
    });

    test('a per-km vehicle with no rate falls back to the ratio', () {
      final v = vehicleFor(outCityMode: 'perKm');
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true),
        9500,
      );
    });
  });

  group('unitFor / totalFor — fixed-route mode', () {
    test('unit is the route flat price, plus prorated driver', () {
      final v = vehicleFor(outCityMode: 'fixedRoute', outCityFixedRouteId: 'route-lhr-isb');
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true, fixedRoute: route),
        18000,
      );
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: true, isOutOfCity: true, fixedRoute: route, driverRatePerDayPkr: 1500),
        19500,
      );
    });

    test('total is the flat route price plus driver per day — never × days', () {
      final v = vehicleFor(outCityMode: 'fixedRoute', outCityFixedRouteId: 'route-lhr-isb');
      // 18000 + 1500 × 3 days + 2 nights × 2000 stay — NOT 18000 × 3.
      expect(
        ManualBookingPackageSelector.totalFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: true, isOutOfCity: true, pickup: pickup, returnTime: threeDays, fixedRoute: route, driverRatePerDayPkr: 1500),
        26500,
      );
      expect(
        ManualBookingPackageSelector.totalFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true, pickup: pickup, returnTime: threeDays, fixedRoute: route),
        18000,
      );
    });

    test('without a chosen route the total falls back to the ratio', () {
      final v = vehicleFor(outCityMode: 'fixedRoute', outCityFixedRouteId: 'route-lhr-isb');
      expect(
        ManualBookingPackageSelector.unitFor(
            vehicle: v, package: pkg(v, '24h'), isWithDriver: false, isOutOfCity: true),
        9500,
      );
    });
  });

  group('optionsFor — customer picker', () {
    List<PackageTierOption> options(VehicleEntity v, {bool isOutOfCity = true, FixedRouteEntity? fixedRoute}) =>
        PackageTierList.optionsFor(
          vehicle: v,
          isWithDriver: false,
          dailySelfDriveRate: 7000,
          dailyWithDriverRate: 8500,
          hourlyRate: 1000,
          isOutOfCity: isOutOfCity,
          fixedRoute: fixedRoute,
        );

    test('per-day mode scales by the ratio', () {
      final daily = options(vehicleFor()).firstWhere((o) => o.label == '24h');
      expect(daily.price, 9500);
      expect(daily.kmIncluded, '350 km/day');
      expect(daily.perKmRatePkr, isNull);
    });

    test('per-km mode prices the estimate and carries the rate', () {
      final opts = options(vehicleFor(outCityMode: 'perKm', outCityPerKmPkr: 30));
      final daily = opts.firstWhere((o) => o.label == '24h');
      expect(daily.price, 10500);
      expect(daily.perKmRatePkr, 30);
      expect(daily.perKmKmPerDay, 350);
      expect(daily.kmIncluded, '350 km');
      final six = opts.firstWhere((o) => o.label == '6h');
      expect(six.price, 2625);
      expect(six.perKmRatePkr, 30);
    });

    test('per-km mode does not apply in-city', () {
      final daily = options(vehicleFor(outCityMode: 'perKm', outCityPerKmPkr: 30), isOutOfCity: false)
          .firstWhere((o) => o.label == '24h');
      expect(daily.price, 7000);
      expect(daily.perKmRatePkr, isNull);
    });

    test('a chosen fixed route prices every tier at the flat route price', () {
      final opts = options(vehicleFor(outCityMode: 'fixedRoute', outCityFixedRouteId: 'route-lhr-isb'), fixedRoute: route);
      expect(opts.every((o) => o.price == 18000), isTrue);
      expect(opts.every((o) => o.kmIncluded == '300 km'), isTrue);
    });

    test('fixed-route mode without a chosen route falls back to the ratio', () {
      final daily = options(vehicleFor(outCityMode: 'fixedRoute', outCityFixedRouteId: 'route-lhr-isb'))
          .firstWhere((o) => o.label == '24h');
      expect(daily.price, 9500);
    });
  });
}
