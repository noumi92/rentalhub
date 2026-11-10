import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/features/admin/data/repositories/platform_settings_repository.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/bookings/utils/unverified_shop_gate.dart';
import 'package:rentalhub/features/customer/data/datasources/review_remote_data_source.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/trust/data/services/trust_score_service.dart';

/// Admin-integration audit contracts (2026-11-10): the seams between
/// the admin panel and the mobile app, tested without Firestore
/// (rulebook D12: no fake_cloud_firestore in this repo — Firestore
/// paths fail open to the in-memory fallback, which is what these
/// tests exercise). Each group pins one audit finding so a later
/// change cannot silently re-break the seam.
void main() {
  group('Seam 2 — ShopModel honesty flags', () {
    test('a doc with no rating/cars/distance/city invents nothing', () {
      final shop = ShopModel.fromMap({
        'shop_name': 'No Data Motors',
        'is_verified': false,
        'verification_status': 'pending',
      }, id: 'shop-1');
      expect(shop.hasRealRating, isFalse);
      expect(shop.hasRealAvailableCount, isFalse);
      expect(shop.hasRealDistance, isFalse);
      expect(shop.hasRealLocation, isFalse);
      expect(shop.city, isEmpty);
      // The display-only fallbacks still exist (non-nullable fields)
      // but the flags say they are not real.
      expect(shop.rating, 4.9);
      expect(shop.availableCount, 8);
      expect(shop.distanceKm, 1.2);
      // ... and toMap must not persist the invented numbers.
      final map = shop.toMap();
      expect(map.containsKey('rating'), isFalse);
      expect(map.containsKey('available_count'), isFalse);
      expect(map.containsKey('distance_km'), isFalse);
    });

    test('a doc with real numbers keeps them and persists them', () {
      final shop = ShopModel.fromMap({
        'shop_name': 'Real Motors',
        'city': 'Lahore',
        'rating': 4.2,
        'available_count': 3,
        'distance_km': 2.5,
        'latitude': 31.5,
        'longitude': 74.3,
        'is_verified': true,
        'verification_status': 'approved',
      }, id: 'shop-2');
      expect(shop.hasRealRating, isTrue);
      expect(shop.hasRealAvailableCount, isTrue);
      expect(shop.hasRealDistance, isTrue);
      expect(shop.hasRealLocation, isTrue);
      expect(shop.city, 'Lahore');
      expect(shop.rating, 4.2);
      expect(shop.availableCount, 3);
      expect(shop.distanceKm, 2.5);
      final map = shop.toMap();
      expect(map['rating'], 4.2);
      expect(map['available_count'], 3);
      expect(map['distance_km'], 2.5);
    });

    test('suspended flag survives fromMap', () {
      final shop = ShopModel.fromMap({
        'shop_name': 'Suspended Motors',
        'suspended': true,
        'suspension_reason': 'Unpaid dues',
      }, id: 'shop-3');
      expect(shop.suspended, isTrue);
      expect(shop.suspensionReason, 'Unpaid dues');
    });
  });

  group('Seam 2/5 — suspension + unverified booking gate', () {
    UnverifiedShopBookingGate gate({
      required bool verified,
      required bool suspended,
      bool allowUnverified = true,
    }) {
      return UnverifiedShopBookingGate(
        settings: _FixedSettings(allowUnverified),
        shopVerifiedLookup: (_) async => verified,
        shopSuspendedLookup: (_) async => suspended,
      );
    }

    test('suspended shop is suspended from its doc data', () {
      expect(shopSuspendedFromData(null), isFalse);
      expect(shopSuspendedFromData({}), isFalse);
      expect(shopSuspendedFromData({'suspended': true}), isTrue);
      expect(shopSuspendedFromData({'suspended': false}), isFalse);
    });

    test('suspended shop blocks booking — online and walk-in alike', () async {
      final ds = BookingRemoteDataSource(
        unverifiedShopGate: gate(verified: true, suspended: true),
      );
      for (final customerId in ['cust-1', 'walkin-123']) {
        await expectLater(
          ds.createBookingRequest(
            customerId: customerId,
            shopId: 'shop-suspended',
            vehicleId: 'veh-1',
            packageType: '24h',
            isWithDriver: false,
            pickupTime: DateTime(2026, 11, 12),
            returnTime: DateTime(2026, 11, 13),
            totalAmount: 5000,
            advanceRequired: 1000,
          ),
          throwsA(isA<ServerException>()),
        );
      }
    });

    test('unverified shop with bookings disabled blocks online only',
        () async {
      final ds = BookingRemoteDataSource(
        unverifiedShopGate:
            gate(verified: false, suspended: false, allowUnverified: false),
      );
      await expectLater(
        ds.createBookingRequest(
          customerId: 'cust-1',
          shopId: 'shop-unverified',
          vehicleId: 'veh-1',
          packageType: '24h',
          isWithDriver: false,
          pickupTime: DateTime(2026, 11, 12),
          returnTime: DateTime(2026, 11, 13),
          totalAmount: 5000,
          advanceRequired: 1000,
        ),
        throwsA(isA<ServerException>()),
      );
      // Walk-ins are exempt from the unverified-booking gate.
      final walkIn = await ds.createBookingRequest(
        customerId: 'walkin-123',
        shopId: 'shop-unverified',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 12),
        returnTime: DateTime(2026, 11, 13),
        totalAmount: 5000,
        advanceRequired: 1000,
      );
      expect(walkIn.shopId, 'shop-unverified');
    });

    test('verified, unsuspended shop books normally', () async {
      final ds = BookingRemoteDataSource(
        unverifiedShopGate: gate(verified: true, suspended: false),
      );
      final booking = await ds.createBookingRequest(
        customerId: 'cust-1',
        shopId: 'shop-ok',
        vehicleId: 'veh-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 12),
        returnTime: DateTime(2026, 11, 13),
        totalAmount: 5000,
        advanceRequired: 1000,
      );
      expect(booking.status, 'requested');
    });
  });

  group('Seam 3 — trust score: one formula on both sides', () {
    test('a verified new customer scores 3.5, not the stored 5.0', () {
      final score = TrustScoreCalculator.calculate(
        kycStatus: 'verified',
        completedTrips: 0,
        meanOwnerRating: null,
        onTimeReturns: 0,
        lateReturns: 0,
        adverseEvents: 0,
      );
      expect(score.total, 3.5);
      // The old mobile behaviour showed the stored 5.0 default for
      // every customer; the live service must not reproduce it.
      expect(score.total, isNot(5.0));
    });

    test('a perfect record scores 5.0 (clamped)', () {
      final score = TrustScoreCalculator.calculate(
        kycStatus: 'verified',
        completedTrips: 10,
        meanOwnerRating: 5.0,
        onTimeReturns: 10,
        lateReturns: 0,
        adverseEvents: 0,
      );
      expect(score.total, 5.0);
    });

    test('live computation returns null without Firestore, never throws',
        () async {
      expect(await const TrustScoreService().compute('cust-1'), isNull);
    });
  });

  group('Seam 3 — blacklist appeals can actually be filed', () {
    test('submitAppeal rejects empty input without touching Firestore',
        () async {
      final ds = BlacklistRemoteDataSource();
      expect(await ds.submitAppeal(blacklistId: '', reason: 'x'), isFalse);
      expect(
          await ds.submitAppeal(blacklistId: 'BLK-1', reason: '  '), isFalse);
    });

    test('submitAppeal fails safe with no Firestore', () async {
      final ds = BlacklistRemoteDataSource();
      expect(
          await ds.submitAppeal(
              blacklistId: 'BLK-1', reason: 'Wrong person'),
          isFalse);
    });
  });

  group('Seam 4 — hidden reviews stop counting', () {
    test('moderation_status hidden is a hidden review', () {
      expect(
          ReviewRemoteDataSource.isHiddenReview(
              {'moderation_status': 'hidden'}),
          isTrue);
      expect(
          ReviewRemoteDataSource.isHiddenReview(
              {'moderation_status': 'visible'}),
          isFalse);
      expect(ReviewRemoteDataSource.isHiddenReview({}), isFalse);
    });

    test('visible reviews round-trip through the in-memory fallback',
        () async {
      final ds = ReviewRemoteDataSource();
      await ds.submitOwnerReview(
        bookingId: 'bk-1',
        shopId: 'shop-1',
        customerId: 'cust-1',
        punctualityRating: 5,
        careRating: 4,
        behaviorRating: 5,
      );
      final reviews =
          await ds.getCustomerReviews('cust-1', onlyOwnerRated: true);
      expect(reviews.length, 1);
      expect(reviews.first['punctualityRating'], 5);
      final single = await ds.getReview('bk-1');
      expect(single, isNotNull);
    });
  });
}

class _FixedSettings extends PlatformSettingsRepository {
  const _FixedSettings(this._allow);

  final bool _allow;

  @override
  Future<bool> displayUnverifiedShops() async => true;

  @override
  Future<bool> allowBookingsFromUnverifiedShops() async => _allow;
}
