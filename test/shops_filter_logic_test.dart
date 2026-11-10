import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shops_filter_logic.dart';

ShopEntity shop({
  required String id,
  required String name,
  required String city,
  required double lat,
  required double lng,
  bool isVerified = true,
  String verificationStatus = 'approved',
  bool hasRealLocation = true,
}) {
  return ShopEntity(
    shopId: id,
    ownerId: 'owner-$id',
    shopName: name,
    phoneNumber: '03000000000',
    address: 'Somewhere, $city',
    city: city,
    geoLocation: GeoPointEntity(lat, lng),
    isVerified: isVerified,
    verificationStatus: verificationStatus,
    hasRealLocation: hasRealLocation,
  );
}

void main() {
  final lahoreVerified = shop(
      id: 'lhr', name: 'Lahore Motors', city: 'Lahore',
      lat: 31.5204, lng: 74.3587);
  final karachiUnverified = shop(
      id: 'khi', name: 'Karachi Rentals', city: 'Karachi',
      lat: 24.8607, lng: 67.0011,
      isVerified: false, verificationStatus: 'pending');
  final multanApproved = shop(
      id: 'mul', name: 'Multan Cars', city: 'Multan',
      lat: 30.1575, lng: 71.5249,
      isVerified: false, verificationStatus: 'approved');
  final all = [lahoreVerified, karachiUnverified, multanApproved];

  group('isShopVerified', () {
    test('is_verified true is verified', () {
      expect(isShopVerified(lahoreVerified), isTrue);
    });

    test('verification_status approved counts as verified', () {
      // The documents carry 'approved', not 'verified'.
      expect(isShopVerified(multanApproved), isTrue);
    });

    test('pending + is_verified false is unverified', () {
      expect(isShopVerified(karachiUnverified), isFalse);
    });
  });

  group('filterShopsForDisplay', () {
    test('default filter (all) shows every shop, unverified included', () {
      final shown = filterShopsForDisplay(
        shops: all,
        city: null,
        verification: ShopVerificationFilter.all,
        displayUnverifiedShops: true,
      );
      expect(shown.map((s) => s.shopId), containsAll(['lhr', 'khi', 'mul']));
    });

    test('verified filter shows verified only', () {
      final shown = filterShopsForDisplay(
        shops: all,
        city: null,
        verification: ShopVerificationFilter.verified,
        displayUnverifiedShops: true,
      );
      expect(shown.map((s) => s.shopId), ['lhr', 'mul']);
    });

    test('unverified filter shows unverified only', () {
      final shown = filterShopsForDisplay(
        shops: all,
        city: null,
        verification: ShopVerificationFilter.unverified,
        displayUnverifiedShops: true,
      );
      expect(shown.map((s) => s.shopId), ['khi']);
    });

    test('city filter matches shop_city case-insensitively', () {
      final shown = filterShopsForDisplay(
        shops: all,
        city: 'lahore',
        verification: ShopVerificationFilter.all,
        displayUnverifiedShops: true,
      );
      expect(shown.map((s) => s.shopId), ['lhr']);
    });

    test('displayUnverifiedShops OFF hides unverified even for all', () {
      final shown = filterShopsForDisplay(
        shops: all,
        city: null,
        verification: ShopVerificationFilter.all,
        displayUnverifiedShops: false,
      );
      expect(shown.map((s) => s.shopId), ['lhr', 'mul']);
    });

    test('displayUnverifiedShops OFF + unverified filter is empty', () {
      final shown = filterShopsForDisplay(
        shops: all,
        city: null,
        verification: ShopVerificationFilter.unverified,
        displayUnverifiedShops: false,
      );
      expect(shown, isEmpty);
    });
  });

  group('sortShopsByDistance', () {
    test('haversine Lahore–Karachi is about a thousand kilometres', () {
      final km = haversineKm(31.5204, 74.3587, 24.8607, 67.0011);
      expect(km, greaterThan(900));
      expect(km, lessThan(1200));
    });

    test('nearest first with recomputed distances', () {
      final sorted = sortShopsByDistance(
          all, const ll.LatLng(31.5204, 74.3587));
      expect(sorted.map((s) => s.shopId), ['lhr', 'mul', 'khi']);
      expect(sorted.first.distanceKm, lessThan(1));
      expect(sorted.last.distanceKm, greaterThan(900));
    });

    test('moving the point re-sorts', () {
      final fromKarachi = sortShopsByDistance(
          all, const ll.LatLng(24.8607, 67.0011));
      expect(fromKarachi.first.shopId, 'khi');
    });
  });
}
