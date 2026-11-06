import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/usecases/add_vehicle_usecase.dart';
import '../../domain/usecases/get_shop_vehicles_usecase.dart';
import '../../domain/usecases/update_vehicle_pricing_usecase.dart';
import '../../domain/usecases/update_vehicle_status_usecase.dart';
import 'fleet_state.dart';

class FleetCubit extends Cubit<FleetState> {
  final AddVehicleUseCase addVehicleUseCase;
  final GetShopVehiclesUseCase getShopVehiclesUseCase;
  final UpdateVehicleStatusUseCase updateVehicleStatusUseCase;
  final UpdateVehiclePricingUseCase updateVehiclePricingUseCase;

  FleetCubit({
    required this.addVehicleUseCase,
    required this.getShopVehiclesUseCase,
    required this.updateVehicleStatusUseCase,
    required this.updateVehiclePricingUseCase,
  }) : super(const FleetInitial());

  Future<void> loadVehicles(String shopId, {String tier = 'basic'}) async {
    emit(const FleetLoading());
    try {
      final list = await getShopVehiclesUseCase(shopId);
      emit(FleetLoaded(vehicles: list, tier: tier));
    } catch (e) {
      emit(FleetError(e.toString()));
    }
  }

  Future<void> addVehicle({
    required String shopId,
    required VehicleEntity vehicle,
    String tier = 'basic',
  }) async {
    try {
      await addVehicleUseCase(shopId: shopId, vehicle: vehicle);
      final list = await getShopVehiclesUseCase(shopId);
      emit(FleetLoaded(vehicles: list, tier: tier));
    } catch (e) {
      emit(FleetError(e.toString()));
    }
  }

  /// Phase B (B1): availability toggle from the fleet list. Reloads the
  /// list so the UI always shows what Firestore (or the in-memory
  /// fallback) actually holds.
  Future<void> updateVehicleStatus({
    required String shopId,
    required String vehicleId,
    required String status,
    String tier = 'basic',
  }) async {
    try {
      await updateVehicleStatusUseCase(
        vehicleId: vehicleId,
        status: status,
      );
      final list = await getShopVehiclesUseCase(shopId);
      emit(FleetLoaded(vehicles: list, tier: tier));
    } catch (e) {
      emit(FleetError(e.toString()));
    }
  }

  /// Phase B (B2): saves the rate matrix, then reloads the list.
  Future<void> updateVehiclePricing({
    required String shopId,
    required VehicleEntity vehicle,
    String tier = 'basic',
  }) async {
    try {
      await updateVehiclePricingUseCase(
        vehicleId: vehicle.vehicleId,
        vehicle: vehicle,
      );
      final list = await getShopVehiclesUseCase(shopId);
      emit(FleetLoaded(vehicles: list, tier: tier));
    } catch (e) {
      emit(FleetError(e.toString()));
    }
  }
}

