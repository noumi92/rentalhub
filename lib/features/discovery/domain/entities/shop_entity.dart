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
  final String? logoUrl;
  final String? headerUrl;
  final List<String> fleetPhotos;
  final Map<String, dynamic> kycDocuments;
  final String verificationStatus;
  final String? ownerName;
  final String? cnicNumber;
  final String? openingHours;
  // Shops tab: true only when the shop document actually stored a
  // location. ShopModel.fromMap defaults a missing lat/lng to Gulberg,
  // Lahore — a shop without a stored location must never get a pin
  // at that default, so the model records whether the pin is real.
  // Directly constructed entities (owner onboarding always pins the
  // shop on the map) default to true.
  final bool hasRealLocation;
  // Admin-integration audit (2026-11-10): the same honesty rule for
  // the other display numbers. ShopModel.fromMap still fills
  // display-only fallbacks (rating 4.9, 8 cars, 1.2 km) so existing
  // non-nullable call sites keep working, but a shop document that
  // never stored the value must never be SHOWN with the fallback —
  // the views hide the number when its flag is false. Directly
  // constructed entities default to true, as with hasRealLocation.
  final bool hasRealRating;
  final bool hasRealAvailableCount;
  final bool hasRealDistance;
  // Phase B (B2): the shop's subscription plan ('free' until Phase F
  // sets real plans) and the suspension state, set by an admin.
  final String plan;
  final bool suspended;
  final String? suspensionReason;
  // F-M3 (admin audit 2026-11-14): the admin's decision reason on
  // the shop application — `rejection_reason` for a rejection,
  // `admin_note` for "ask for more info". Stored on the shops doc
  // by decideShopApplication and delivered to the owner as an
  // in-app notification; kept on the model so any owner-side view
  // (e.g. the onboarding status step) can show the reason itself
  // instead of only the bare status.
  final String? rejectionReason;
  final String? adminNote;

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
    this.logoUrl,
    this.headerUrl,
    this.fleetPhotos = const [],
    this.kycDocuments = const {},
    this.verificationStatus = 'approved',
    this.ownerName,
    this.cnicNumber,
    this.openingHours,
    this.plan = 'free',
    this.suspended = false,
    this.suspensionReason,
    this.rejectionReason,
    this.adminNote,
    this.hasRealLocation = true,
    this.hasRealRating = true,
    this.hasRealAvailableCount = true,
    this.hasRealDistance = true,
  });

  /// Copy with a recomputed distance — the Shops map re-sorts by
  /// distance from the draggable "you are here" pin without
  /// mutating the stored entity. A recomputed distance is real, so
  /// [hasRealDistance] becomes true.
  ShopEntity withDistance(double distanceKm) => ShopEntity(
        shopId: shopId,
        ownerId: ownerId,
        shopName: shopName,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        geoLocation: geoLocation,
        distanceKm: distanceKm,
        rating: rating,
        availableCount: availableCount,
        isVerified: isVerified,
        bankAccounts: bankAccounts,
        logoUrl: logoUrl,
        headerUrl: headerUrl,
        fleetPhotos: fleetPhotos,
        kycDocuments: kycDocuments,
        verificationStatus: verificationStatus,
        ownerName: ownerName,
        cnicNumber: cnicNumber,
        openingHours: openingHours,
        plan: plan,
        suspended: suspended,
        suspensionReason: suspensionReason,
        rejectionReason: rejectionReason,
        adminNote: adminNote,
        hasRealLocation: hasRealLocation,
        hasRealRating: hasRealRating,
        hasRealAvailableCount: hasRealAvailableCount,
        hasRealDistance: true,
      );

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
        logoUrl,
        headerUrl,
        fleetPhotos,
        kycDocuments,
        verificationStatus,
        ownerName,
        cnicNumber,
        openingHours,
        plan,
        suspended,
        suspensionReason,
        rejectionReason,
        adminNote,
        hasRealLocation,
        hasRealRating,
        hasRealAvailableCount,
        hasRealDistance,
      ];
}

