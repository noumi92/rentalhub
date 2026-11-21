import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_settings_data_source.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_settings_entity.dart';
import 'package:rentalhub/features/discovery/presentation/views/vehicle_detail_view.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/customer_vehicle_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/shop_vehicle_card.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/vehicle_detail_packages.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_price_estimate_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Worker 3 (2026-11-21): the five DISPLAY spots for the with-driver
// daily rate follow the shop's booking-settings driver rate
// (`booking_settings/{shopId}`), not the vehicle's stored
// `withDriverSurchargePkr`. The vehicle below deliberately carries a
// STALE surcharge of 1500 (daily 6000 -> stale with-driver 7,500)
// while the setting is 2500 (with-driver 8,500), so any test that
// passes proves the display read the setting, not the vehicle field.
// Setting unset -> the surcharge is 0: the with-driver rate equals
// the self-drive rate (cards / detail) or the surcharge row is hidden
// (price estimate).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vehicle = VehicleEntity(
    vehicleId: 'veh-display-driver-rate-1',
    shopId: 'shop-1',
    make: 'Toyota',
    model: 'Corolla',
    year: 2022,
    plateNumber: 'LEA-1000',
    rates: VehicleRatesEntity(
      hourly1: 1500,
      hourly3: 3500,
      hourly6: 6000,
      daily24: 6000,
      outOfCityDaily: 7500,
    ),
    weeklyRate: 36000,
    securityDepositPkr: 20000,
    extraHourPkr: 600,
    withDriverSurchargePkr: 1500,
    fuelPolicy: 'Same to Same',
    packages: [
      VehiclePackageEntity(
          label: '24h', hours: 24, pricePkr: 6000, kmIncluded: 250),
    ],
  );

  Future<BookingSettingsDataSource> seededDs() async {
    final ds = BookingSettingsDataSource();
    await ds.saveSettings(const BookingSettingsEntity(
        shopId: 'shop-1', driverRatePerDayPkr: 2500));
    return ds;
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(wrap(card));
    await tester.pumpAndSettle();
  }

  /// Full-screen views (their own Scaffold + Expanded) cannot sit
  /// inside the scroll wrapper above — unbounded height breaks
  /// their layout — so they pump directly as the app home.
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DefaultAssetBundle(bundle: _TestAssetBundle(), child: screen),
    ));
    await tester.pumpAndSettle();
  }

  group('CustomerVehicleCard follows the booking setting', () {
    testWidgets('setting 2500 -> with-driver rate 8,500, not stale 7,500',
        (tester) async {
      await pumpCard(
        tester,
        CustomerVehicleCard(
          vehicle: vehicle,
          onTap: () {},
          settingsDataSource: await seededDs(),
        ),
      );
      expect(find.textContaining('8,500'), findsOneWidget);
      expect(find.textContaining('7,500'), findsNothing);
    });

    testWidgets('setting unset -> with-driver rate equals self-drive 6,000',
        (tester) async {
      await pumpCard(
        tester,
        CustomerVehicleCard(
          vehicle: vehicle,
          onTap: () {},
          settingsDataSource: BookingSettingsDataSource(),
        ),
      );
      expect(find.textContaining('7,500'), findsNothing);
      expect(find.textContaining('6,000'), findsWidgets);
    });
  });

  group('ShopVehicleCard follows the booking setting', () {
    testWidgets('setting 2500 -> with-driver rate 8,500, not stale 7,500',
        (tester) async {
      await pumpCard(
        tester,
        ShopVehicleCard(
          vehicle: vehicle,
          onTap: () {},
          settingsDataSource: await seededDs(),
        ),
      );
      expect(find.textContaining('8,500'), findsOneWidget);
      expect(find.textContaining('7,500'), findsNothing);
    });

    testWidgets('setting unset -> with-driver rate equals self-drive 6,000',
        (tester) async {
      await pumpCard(
        tester,
        ShopVehicleCard(
          vehicle: vehicle,
          onTap: () {},
          settingsDataSource: BookingSettingsDataSource(),
        ),
      );
      expect(find.textContaining('7,500'), findsNothing);
      expect(find.textContaining('6,000'), findsWidgets);
    });
  });

  group('VehicleDetailPackages follows the booking setting', () {
    testWidgets('setting 2500 -> with-driver package 8,500',
        (tester) async {
      await pumpCard(
        tester,
        VehicleDetailPackages(
          vehicle: vehicle,
          // Self-drive selected: the detail slab shows the deposit
          // text, not the outstation line (whose real out-city rate
          // is 7,500 and would collide with the stale-value check).
          withDriver: false,
          driverRatePerDayPkr: 2500,
          onDriveModeChanged: (_) {},
        ),
      );
      expect(find.textContaining('8,500'), findsOneWidget);
      expect(find.textContaining('7,500'), findsNothing);
    });

    testWidgets('setting unset (null) -> with-driver package equals 6,000',
        (tester) async {
      await pumpCard(
        tester,
        VehicleDetailPackages(
          vehicle: vehicle,
          withDriver: false,
          onDriveModeChanged: (_) {},
        ),
      );
      expect(find.textContaining('7,500'), findsNothing);
      expect(find.textContaining('6,000'), findsWidgets);
    });
  });

  group('VehicleDetailView loads the booking setting', () {
    testWidgets('setting 2500 -> package price and Book Now rate 8,500',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: VehicleDetailView(
            vehicle: vehicle,
            shopName: 'Test Shop',
            shopPhone: '+923001234567',
            settingsDataSource: await seededDs(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('8,500'), findsWidgets);
      expect(find.textContaining('7,500'), findsNothing);
      // Switch to with-driver: the Book Now button rate follows too.
      await tester.ensureVisible(find.text('With Driver'));
      await tester.tap(find.text('With Driver'));
      await tester.pumpAndSettle();
      expect(find.textContaining('8,500/day'), findsOneWidget);
    });

    testWidgets('setting unset -> no stale 7,500 anywhere',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: VehicleDetailView(
            vehicle: vehicle,
            shopName: 'Test Shop',
            shopPhone: '+923001234567',
            settingsDataSource: BookingSettingsDataSource(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('7,500'), findsNothing);
    });
  });

  group('OwnerPriceEstimateView follows the booking setting', () {
    testWidgets('setting 2500 -> surcharge row shows 2,500, not stale 1,500',
        (tester) async {
      await pumpScreen(
        tester,
        OwnerPriceEstimateView(
          vehicle: vehicle,
          settingsDataSource: await seededDs(),
        ),
      );
      expect(find.text('With-driver surcharge'), findsOneWidget);
      expect(find.textContaining('2,500'), findsOneWidget);
      expect(find.textContaining('1,500'), findsNothing);
    });

    testWidgets('setting unset -> surcharge row hidden entirely',
        (tester) async {
      await pumpScreen(
        tester,
        OwnerPriceEstimateView(
          vehicle: vehicle,
          settingsDataSource: BookingSettingsDataSource(),
        ),
      );
      expect(find.text('With-driver surcharge'), findsNothing);
      expect(find.textContaining('1,500'), findsNothing);
    });
  });
}

class _TestAssetBundle extends AssetBundle {
  static final ByteData _pixel = ByteData.view(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ).buffer);

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec()
          .encodeMessage(<String, Object>{})!;
    }
    return _pixel;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '{}';
}
