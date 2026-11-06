import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/fixed_route_entity.dart';
import '../models/fixed_route_model.dart';

/// Phase B (B3): fixed routes of a shop, from Firestore with an
/// in-memory fallback. The fallback seeds the six Lahore routes for
/// the demo shop; the prices are samples the owner edits in the app.
class FixedRouteRemoteDataSource {
  final FirebaseFirestore? _firestore;

  final List<FixedRouteModel> _inMemoryRoutes = [
    const FixedRouteModel(
      routeId: 'route-lhr-isb',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Islamabad',
      distanceKm: 300,
      fixedPricePkr: 18000,
    ),
    const FixedRouteModel(
      routeId: 'route-lhr-rwp',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Rawalpindi',
      distanceKm: 290,
      fixedPricePkr: 17000,
    ),
    const FixedRouteModel(
      routeId: 'route-lhr-murree',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Murree',
      distanceKm: 350,
      fixedPricePkr: 22000,
    ),
    const FixedRouteModel(
      routeId: 'route-lhr-fsd',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Faisalabad',
      distanceKm: 180,
      fixedPricePkr: 12000,
    ),
    const FixedRouteModel(
      routeId: 'route-lhr-mul',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Multan',
      distanceKm: 340,
      fixedPricePkr: 20000,
    ),
    const FixedRouteModel(
      routeId: 'route-lhr-khi',
      shopId: 'shop-1',
      originCity: 'Lahore',
      destinationCity: 'Karachi',
      distanceKm: 1350,
      fixedPricePkr: 45000,
    ),
  ];

  FixedRouteRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<List<FixedRouteEntity>> getShopFixedRoutes(String shopId) async {
    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('fixed_routes')
            .where('shopId', isEqualTo: shopId)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => FixedRouteModel.fromMap(d.data(), d.id))
              .toList();
        }
      } catch (_) {}
    }
    return _inMemoryRoutes.where((r) => r.shopId == shopId).toList();
  }

  Future<void> saveFixedRoute(FixedRouteEntity route) async {
    final model = FixedRouteModel.fromEntity(route);
    final idx =
        _inMemoryRoutes.indexWhere((r) => r.routeId == route.routeId);
    if (idx != -1) {
      _inMemoryRoutes[idx] = model;
    } else {
      _inMemoryRoutes.add(model);
    }

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs
            .collection('fixed_routes')
            .doc(route.routeId)
            .set(model.toMap());
      } catch (_) {}
    }
  }

  Future<void> deleteFixedRoute(String routeId) async {
    _inMemoryRoutes.removeWhere((r) => r.routeId == routeId);

    final fs = _resolvedFirestore;
    if (fs != null) {
      try {
        await fs.collection('fixed_routes').doc(routeId).delete();
      } catch (_) {}
    }
  }
}
