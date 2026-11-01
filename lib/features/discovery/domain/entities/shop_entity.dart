import 'package:equatable/equatable.dart';

class GeoPointEntity extends Equatable {
  final double latitude;
  final double longitude;

  const GeoPointEntity(this.latitude, this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];
}

class ShopEntity extends Equatable {
  final String shopId;
  final String ownerId;
  final String shopName;
  final String phoneNumber;
  final String address;
  final String city;
  final GeoPointEntity geoLocation;
  final double distanceKm;
  final double rating;
  final int availableCount;
  final bool isVerified;
  final List<Map<String, dynamic>> bankAccounts;

  const ShopEntity({
    required this.shopId,
    required this.ownerId,
    required this.shopName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.geoLocation,
    this.distanceKm = 1.2,
    this.rating = 4.9,
    this.availableCount = 8,
    this.isVerified = true,
    this.bankAccounts = const [],
  });

  @override
  List<Object?> get props => [
        shopId,
        ownerId,
        shopName,
        phoneNumber,
        address,
        city,
        geoLocation,
        distanceKm,
        rating,
        availableCount,
        isVerified,
        bankAccounts,
      ];
}

