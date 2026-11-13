/// CU-M9: the ONE make/model → asset-illustration mapping for the
/// customer side. [ShopVehicleCard] and [VehicleDetailView] used to
/// carry identical copies that drifted — a Kia Sportage or Honda BR-V
/// was shown as a red Honda Civic. Only Civic / Corolla / Yaris have
/// a matching illustration; everything else (including Sportage and
/// BR-V) falls back to the generic sedan until a real asset exists.
String vehicleImageAsset(String make, String model) {
  final nameLower = '$make $model'.toLowerCase();
  if (nameLower.contains('civic')) {
    return 'assets/images/honda_civic_hero.png';
  }
  if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
    return 'assets/images/toyota_corolla.png';
  }
  return 'assets/images/white_sedan_hero.png';
}
