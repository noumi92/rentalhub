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
    super.plan,
    super.suspended,
    super.suspensionReason,
    super.hasRealLocation,
    super.hasRealRating,
    super.hasRealAvailableCount,
    super.hasRealDistance,
  });

  factory ShopModel.fromMap(Map<String, dynamic> d, {String? id}) {
    // Shops tab: a document with no stored location must not inherit
    // a pin. The 31.5102/74.3441 fallback below is display-only for
    // the legacy non-nullable geoLocation; [hasRealLocation] records
    // whether the document actually stored coordinates — a Firestore
    // GeoPoint `location` field, or numeric `latitude`/`longitude`.
    //
    // Admin-integration audit (2026-11-10): the same rule for the
    // other display numbers. The fallbacks below (rating 4.9, 8
    // available cars, 1.2 km, city 'Lahore') are display-only
    // placeholders for the non-nullable fields — the hasReal* flags
    // record whether the document actually stored the value, and
    // the views hide the number when its flag is false. A missing
    // city is now '' (unknown), never an invented 'Lahore'.
    double? lat;
    double? lng;
    final storedPoint = d['location'];
    if (storedPoint != null) {
      try {
        lat = (storedPoint.latitude as num).toDouble();
        lng = (storedPoint.longitude as num).toDouble();
      } catch (_) {
        lat = null;
        lng = null;
      }
    }
    if ((lat == null || lng == null) &&
        d['latitude'] is num &&
        d['longitude'] is num) {
      lat = (d['latitude'] as num).toDouble();
      lng = (d['longitude'] as num).toDouble();
    }
    final hasRealLocation = lat != null && lng != null;
    lat ??= 31.5102;
    lng ??= 74.3441;
    final city = (d['city'] as String?)?.trim() ?? '';
    return ShopModel(
      shopId: id ?? d['shop_id'] ?? '',
      ownerId: d['owner_id'] ?? '',
      shopName: d['shop_name'] ?? '',
      phoneNumber: d['phone_number'] ?? '',
      address: d['address'] ?? '',
      city: city,
      geoLocation: GeoPointEntity(lat, lng),
      distanceKm: (d['distance_km'] as num?)?.toDouble() ?? 1.2,
      rating: (d['rating'] as num?)?.toDouble() ?? 4.9,
      availableCount: (d['available_count'] as num?)?.toInt() ?? 8,
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
      plan: d['plan'] as String? ?? 'free',
      suspended: d['suspended'] as bool? ?? false,
      suspensionReason: d['suspension_reason'] as String?,
      hasRealLocation: hasRealLocation,
      hasRealRating: d['rating'] is num,
      hasRealAvailableCount: d['available_count'] is num,
      hasRealDistance: d['distance_km'] is num,
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
      // The display-only fallbacks (4.9 / 8 / 1.2) are never written
      // back: persisting them would turn an invented number into a
      // stored fact. Only values the document actually had are kept.
      if (hasRealDistance) 'distance_km': distanceKm,
      if (hasRealRating) 'rating': rating,
      if (hasRealAvailableCount) 'available_count': availableCount,
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
      'plan': plan,
      'suspended': suspended,
      if (suspensionReason != null)
        'suspension_reason': suspensionReason,
    };
  }
}

