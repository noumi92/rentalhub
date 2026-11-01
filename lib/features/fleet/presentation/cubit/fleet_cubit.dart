import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/usecases/add_vehicle_usecase.dart';
import '../../domain/usecases/get_shop_vehicles_usecase.dart';
import 'fleet_state.dart';

class FleetCubit extends Cubit<FleetState> {
  final AddVehicleUseCase addVehicleUseCase;
  final GetShopVehiclesUseCase getShopVehiclesUseCase;

  FleetCubit({
    required this.addVehicleUseCase,
    required this.getShopVehiclesUseCase,
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
}

