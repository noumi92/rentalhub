import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/customer_location_store.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_nearby_shops_usecase.dart';

abstract class DiscoveryState extends Equatable {
  const DiscoveryState();
  @override
  List<Object?> get props => [];
}

class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

class DiscoveryLoaded extends DiscoveryState {
  final List<ShopEntity> shops;
  final double currentRadiusKm;
  final bool isMapView;

  const DiscoveryLoaded({
    required this.shops,
    required this.currentRadiusKm,
    this.isMapView = false,
  });

  @override
  List<Object?> get props => [shops, currentRadiusKm, isMapView];
}

class DiscoveryEmpty extends DiscoveryState {
  final double currentRadiusKm;
  const DiscoveryEmpty(this.currentRadiusKm);

  @override
  List<Object?> get props => [currentRadiusKm];
}

class DiscoveryCubit extends Cubit<DiscoveryState> {
  final GetNearbyShopsUseCase getNearbyShopsUseCase;
  bool _isMapView = false;
  double _currentRadius = 3.0;
  // B1: the location the search runs from. Starts at the Lahore default
  // (the same city the location prompt opens on); the home view replaces
  // it with the customer's stored pick once it loads.
  CustomerLocation _location = CustomerLocation.defaultLocation;

  DiscoveryCubit({required this.getNearbyShopsUseCase})
      : super(const DiscoveryLoading());

  CustomerLocation get currentLocation => _location;

  /// The customer picked a new location (GPS fix or a city on the
  /// prompt): search from there at the current radius.
  void setLocation(CustomerLocation location) {
    _location = location;
    fetchNearbyShops(radiusKm: _currentRadius);
  }

  Future<void> fetchNearbyShops({required double radiusKm}) async {
    _currentRadius = radiusKm;
    emit(const DiscoveryLoading());
    try {
      final filteredShops = await getNearbyShopsUseCase(
        radiusKm: radiusKm,
        latitude: _location.latitude,
        longitude: _location.longitude,
      );
      if (filteredShops.isEmpty) {
        emit(DiscoveryEmpty(radiusKm));
      } else {
        emit(DiscoveryLoaded(
          shops: filteredShops,
          currentRadiusKm: radiusKm,
          isMapView: _isMapView,
        ));
      }
    } catch (_) {
      emit(DiscoveryEmpty(radiusKm));
    }
  }

  void toggleMapView(bool isMap) {
    _isMapView = isMap;
    final currentState = state;
    if (currentState is DiscoveryLoaded) {
      emit(DiscoveryLoaded(
        shops: currentState.shops,
        currentRadiusKm: currentState.currentRadiusKm,
        isMapView: _isMapView,
      ));
    } else {
      fetchNearbyShops(radiusKm: _currentRadius);
    }
  }
}

