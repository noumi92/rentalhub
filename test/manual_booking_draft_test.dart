import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_draft.dart';
import 'package:rentalhub/l10n/app_localizations_en.dart';

void main() {
  const vehicle = VehicleEntity(
    vehicleId: 'veh-draft-1',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    plateNumber: 'LEA-1000',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 6000,
      outOfCityDaily: 7500,
    ),
    weeklyRate: 36000,
    securityDepositPkr: 20000,
    // No advanceRequiredPkr override: the 25%-of-total rule applies,
    // so the required advance tracks the (fixed) total.
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
      VehiclePackageEntity(
          label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 6000, kmIncluded: 250),
    ],
  );

  ManualBookingDraft draftFor(String packageLabel, bool withDriver) {
    final draft = ManualBookingDraft();
    draft.selectVehicle(vehicle);
    draft.onPackageChanged(
        vehicle.packages.firstWhere((p) => p.label == packageLabel));
    draft.isWithDriver = withDriver;
    return draft;
  }

  group('ManualBookingDraft driver charge', () {
    test('no driver means no driver charge (24h)', () {
      final draft = draftFor('24h', false);
      expect(draft.rentAmount, 6000);
      expect(draft.driverAmount, 0);
      expect(draft.total, 6000);
      // Advance required is 25% of the true total, not of a total
      // inflated by a driver nobody chose.
      expect(draft.advanceRequired, 1500);
    });

    test('no driver means no driver charge (1h)', () {
      final draft = draftFor('1h', false);
      expect(draft.rentAmount, 1500);
      expect(draft.driverAmount, 0);
      expect(draft.total, 1500);
    });

    test('with driver charges the full surcharge (24h)', () {
      final draft = draftFor('24h', true);
      // Worker A (2026-11-21): the charge comes from the shop's
      // booking-settings rate, not the vehicle's stored 1500.
      draft.driverRatePerDayPkr = 1500;
      expect(draft.rentAmount, 6000);
      expect(draft.driverAmount, 1500);
      expect(draft.total, 7500);
      expect(draft.advanceRequired, 1875);
    });

    test('with driver and no setting rate charges nothing (24h)', () {
      final draft = draftFor('24h', true);
      expect(draft.rentAmount, 6000);
      expect(draft.driverAmount, 0);
      expect(draft.total, 6000);
    });

    test('full rent collected with dues off passes validation', () {
      final draft = draftFor('24h', false);
      draft.advanceController.text = '6000';
      draft.addToDues = false;
      expect(draft.advanceReceived, 6000);
      expect(draft.remaining, 0);
      // Before the driver fix the total was 7,500 here, so this
      // returned the "collect in full or add to dues" error and the
      // booking could not be saved.
      expect(draft.validatePayment(AppLocalizationsEn()), isNull);
    });
  });
}
