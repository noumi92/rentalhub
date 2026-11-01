import '../../domain/entities/shop_entity.dart';
import '../models/shop_model.dart';

class DiscoveryRemoteDataSource {
  static final List<ShopModel> _seededShops = [
    const ShopModel(
      shopId: 'shop-1',
      ownerId: 'usr_owner_1',
      shopName: 'Al-Haram Motors & Rent-a-Car',
      phoneNumber: '+92 300 8419201',
      address: 'Main Boulevard Gulberg III',
      city: 'Lahore',
      geoLocation: GeoPointEntity(31.5102, 74.3441),
      distanceKm: 0.8,
      rating: 4.9,
      availableCount: 14,
      isVerified: true,
      bankAccounts: [
        {
          'bank': 'Meezan Bank',
          'title': 'Al-Haram Motors Pvt Ltd',
          'account': 'PK88 MEZN 0002 1940 8172 9012',
        },
        {
          'bank': 'JazzCash',
          'title': 'Haji Tariq Mehmood',
          'account': '0300-8419201',
        },
        {
          'bank': 'EasyPaisa',
          'title': 'Haji Tariq Mehmood',
          'account': '0345-8419201',
        },
      ],
    ),
    const ShopModel(
      shopId: 'shop-2',
      ownerId: 'usr_owner_2',
      shopName: 'Capital Executive Fleet',
      phoneNumber: '+92 321 5192081',
      address: 'Blue Area Jinnah Avenue, F-6',
      city: 'Islamabad',
      geoLocation: GeoPointEntity(33.7182, 73.0714),
      distanceKm: 1.8,
      rating: 4.8,
      availableCount: 9,
      isVerified: true,
      bankAccounts: [
        {
          'bank': 'Meezan Bank',
          'title': 'Capital Executive Fleet',
          'account': 'PK14 MEZN 0001 9921 1029 4410',
        },
      ],
    ),
    const ShopModel(
      shopId: 'shop-3',
      ownerId: 'usr_owner_3',
      shopName: 'DHA Luxury Wheels',
      phoneNumber: '+92 333 4110922',
      address: 'Phase 5 Commercial Broadway, DHA',
      city: 'Lahore',
      geoLocation: GeoPointEntity(31.4697, 74.4111),
      distanceKm: 2.7,
      rating: 4.7,
      availableCount: 11,
      isVerified: true,
      bankAccounts: [
        {
          'bank': 'JazzCash',
          'title': 'DHA Luxury Wheels',
          'account': '0333-4110922',
        },
      ],
    ),
    const ShopModel(
      shopId: 'shop-4',
      ownerId: 'usr_owner_4',
      shopName: 'Clifton Prestige Rentals',
      phoneNumber: '+92 301 2291844',
      address: 'Block 4 Shahrah-e-Firdousi, Clifton',
      city: 'Karachi',
      geoLocation: GeoPointEntity(24.8138, 67.0301),
      distanceKm: 4.3,
      rating: 4.9,
      availableCount: 18,
      isVerified: true,
      bankAccounts: [
        {
          'bank': 'Meezan Bank',
          'title': 'Clifton Prestige Rentals',
          'account': 'PK55 MEZN 0099 8812 3341 0001',
        },
      ],
    ),
  ];

  Future<List<ShopModel>> fetchNearbyShops({required double radiusKm}) async {
    return _seededShops
        .where((shop) => shop.distanceKm <= radiusKm && shop.isVerified)
        .toList();
  }
}

