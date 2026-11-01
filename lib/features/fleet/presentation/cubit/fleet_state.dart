import 'package:equatable/equatable.dart';
import '../../domain/entities/vehicle_entity.dart';

abstract class FleetState extends Equatable {
  const FleetState();
  @override
  List<Object?> get props => [];
}

class FleetInitial extends FleetState {
  const FleetInitial();
}

class FleetLoading extends FleetState {
  const FleetLoading();
}

class FleetLoaded extends FleetState {
  final List<VehicleEntity> vehicles;
  final String tier;

  const FleetLoaded({required this.vehicles, required this.tier});

  @override
  List<Object?> get props => [vehicles, tier];
}

class FleetError extends FleetState {
  final String message;
  const FleetError(this.message);

  @override
  List<Object?> get props => [message];
}

