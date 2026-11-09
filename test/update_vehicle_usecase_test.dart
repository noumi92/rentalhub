import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:rentalhub/features/fleet/domain/usecases/update_vehicle_usecase.dart';

class _FakeFleetRepository implements FleetRepository {
  String? savedDetailsId;
  VehicleEntity? savedDetails;

  @override
  Future<int> getActiveVehicleCount(String shopId) async => 0;

  @override
  Future<String> getShopSubscriptionTier(String shopId) async => 'basic';

  @override
  Future<List<VehicleEntity>> getShopVehicles(String shopId) async => [];

  @override
  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
  }) async {}

  @override
  Future<void> updateVehicleStatus({
    required String vehicleId,
    required String status,
  }) async {}

  @override
  Future<void> updateVehiclePricing({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {}

  @override
  Future<void> updateVehicleDetails({
    required String vehicleId,
    required VehicleEntity vehicle,
  }) async {
    savedDetailsId = vehicleId;
    savedDetails = vehicle;
  }
}

const _vehicle = VehicleEntity(
  vehicleId: 'v-1',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla Grande',
  year: 2022,
  plateNumber: 'LEA-23-4567',
  rates: VehicleRatesEntity(daily24: 8500, outOfCityDaily: 10500),
);

void main() {
  group('UpdateVehicleUseCase', () {
    test('saves the updated entity through updateVehicleDetails', () async {
      final repo = _FakeFleetRepository();
      final updated = _vehicle.copyWith(model: 'Corolla Cross', status: 'maintenance');
      await UpdateVehicleUseCase(repo)(
        vehicleId: 'v-1',
        vehicle: updated,
      );
      expect(repo.savedDetailsId, 'v-1');
      expect(repo.savedDetails?.model, 'Corolla Cross');
      expect(repo.savedDetails?.status, 'maintenance');
      // Identity fields the edit does not touch ride along unchanged.
      expect(repo.savedDetails?.plateNumber, 'LEA-23-4567');
      expect(repo.savedDetails?.rates.daily24, 8500);
    });

    test('throws on vehicleId mismatch', () {
      final repo = _FakeFleetRepository();
      expect(
        () => UpdateVehicleUseCase(repo)(
          vehicleId: 'v-other',
          vehicle: _vehicle,
        ),
        throwsArgumentError,
      );
      expect(repo.savedDetails, isNull);
    });
  });
}
