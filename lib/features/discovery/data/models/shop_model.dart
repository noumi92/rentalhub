import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  const ShopModel({
    required super.shopId,
    required super.ownerId,
    required super.shopName,
    required super.phoneNumber,
    required super.address,
    required super.city,
    required super.geoLocation,
    super.distanceKm,
    super.rating,
    super.availableCount,
    super.isVerified,
    required super.bankAccounts,
    super.logoUrl,
    super.headerUrl,
    super.fleetPhotos,
    super.kycDocuments,
    super.verificationStatus,
    super.ownerName,
    super.cnicNumber,
    super.openingHours,
  });

  factory ShopModel.fromMap(Map<String, dynamic> d, {String? id}) {
    final lat = (d['latitude'] ?? 31.5102).toDouble();
    final lng = (d['longitude'] ?? 74.3441).toDouble();
    return ShopModel(
      shopId: id ?? d['shop_id'] ?? '',
      ownerId: d['owner_id'] ?? '',
      shopName: d['shop_name'] ?? '',
      phoneNumber: d['phone_number'] ?? '',
      address: d['address'] ?? '',
      city: d['city'] ?? 'Lahore',
      geoLocation: GeoPointEntity(lat, lng),
      distanceKm: (d['distance_km'] ?? 1.2).toDouble(),
      rating: (d['rating'] ?? 4.9).toDouble(),
      availableCount: d['available_count'] ?? 8,
      isVerified: d['is_verified'] ?? true,
      bankAccounts: List<Map<String, dynamic>>.from(d['bank_accounts'] ?? []),
      logoUrl: d['logo_url'],
      headerUrl: d['header_url'],
      fleetPhotos: List<String>.from(d['fleet_photos'] ?? []),
      kycDocuments: Map<String, dynamic>.from(d['kyc_documents'] ?? {}),
      verificationStatus: d['verification_status'] ?? (d['is_verified'] == true ? 'approved' : 'pending'),
      ownerName: d['owner_name'],
      cnicNumber: d['cnic_number'],
      openingHours: d['opening_hours'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'owner_id': ownerId,
      'shop_name': shopName,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'latitude': geoLocation.latitude,
      'longitude': geoLocation.longitude,
      'distance_km': distanceKm,
      'rating': rating,
      'available_count': availableCount,
      'is_verified': isVerified,
      'bank_accounts': bankAccounts,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (headerUrl != null) 'header_url': headerUrl,
      'fleet_photos': fleetPhotos,
      'kyc_documents': kycDocuments,
      'verification_status': verificationStatus,
      if (ownerName != null) 'owner_name': ownerName,
      if (cnicNumber != null) 'cnic_number': cnicNumber,
      if (openingHours != null) 'opening_hours': openingHours,
    };
  }
}

