import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/auth/presentation/views/legal_text_view.dart';
import 'package:rentalhub/features/auth/presentation/views/login_view.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/constants/owner_onboarding_constants.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_onboarding_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_share_with_customers_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/add_vehicle/vehicle_rates_step_widget.dart';
import 'package:rentalhub/features/owner/presentation/widgets/onboarding/shop_location_step_widget.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Audit §5 finish (worker C): login Terms/Privacy footer + legal
// screens, city dropdown, step-4 document validation, "Submit for
// Review", in/out-city day rates, share-with-customers screen, and the
// rate matrix split into In-City / Out-City lists. Pure widget tests;
// nothing here taps Share (share_plus) or the map tiles' real network.
// NOTE: needs the registrar's regenerated l10n (new keys) + routes
// before it compiles: authTermsOfService, authPrivacyPolicy,
// authLegalIntro, authLegalAnd, legalTermsBody, legalPrivacyBody,
// onboardingSubmitForReview, onboardingDocRequired,
// addVehicleCityRatesTitle, addVehicleCityRatesHint,
// addVehicleInCityDayRate, addVehicleInCityDayRateHint,
// addVehicleOutCityDayRate, addVehicleOutCityDayRateHint, shareTitle,
// shareStepOfTwo, shareChoosePrice, shareWithCustomersText,
// shareLinkNote, rateMatrixInCityTitle, rateMatrixOutCityTitle,
// RouteNames.legalTermsOfService,
// RouteNames.legalPrivacyPolicy, RouteNames.ownerShareWithCustomers.
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

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DefaultAssetBundle(
      bundle: _TestAssetBundle(),
      child: Scaffold(body: child),
    ),
  );
}

/// The shop-location map fetches OpenStreetMap tiles over the network;
/// in tests every tile answers with the 1px test PNG instead.
class _TileHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TileHttpClient();
}

class _TileHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _TileHttpRequest();

  // flutter_map closes the client when the tile layer disposes; Fake
  // throws UnimplementedError for every member without an override.
  @override
  void close({bool force = false}) {}
}

class _TileHttpRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _TileHttpResponse();
}

class _TileHttpResponse extends Fake implements HttpClientResponse {
  static final List<int> _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _png.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _TileHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(_png).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}

class _TileHttpHeaders extends Fake implements HttpHeaders {
  @override
  ContentType? get contentType => ContentType('image', 'png');
}

const _vehicle = VehicleEntity(
  vehicleId: 'veh-c-1',
  shopId: 'shop-1',
  make: 'Honda',
  model: 'Civic Oriel',
  year: 2021,
  plateNumber: 'LEA-4820',
  rates: VehicleRatesEntity(
    hourly1: 1500,
    hourly3: 3500,
    hourly6: 6000,
    daily24: 9000,
    outOfCityDaily: 11500,
  ),
  weeklyRate: 52000,
  monthlyRate: 216000,
  securityDepositPkr: 20000,
  advanceRequiredPkr: 3000,
  extraHourPkr: 600,
  extraKmPkr: 100,
  outOfCityKmPerDay: 350,
  withDriverSurchargePkr: 1500,
  fuelPolicy: 'Same to Same',
  packages: [
    VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1500, kmIncluded: 15),
    VehiclePackageEntity(label: '3h', hours: 3, pricePkr: 3500, kmIncluded: 40),
    VehiclePackageEntity(label: '6h', hours: 6, pricePkr: 6000, kmIncluded: 80),
    VehiclePackageEntity(label: '12h', hours: 12, pricePkr: 5400, kmIncluded: 150),
    VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 9000, kmIncluded: 250),
    VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 52000, kmIncluded: 1750),
    VehiclePackageEntity(label: 'Monthly', hours: 720, pricePkr: 216000, kmIncluded: 7500),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('P2-1 login Terms/Privacy footer', () {
    testWidgets('shows Terms of Service and Privacy Policy links', (tester) async {
      await tester.pumpWidget(_wrap(const LoginView()));
      await tester.pump();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      // The only TextButtons on the login screen are the two legal
      // links — the old authNewUser bypass button stays removed.
      expect(find.byType(TextButton), findsNWidgets(2));

      // HeroCarSlider runs a periodic timer: dispose the view before
      // the test ends instead of leaving it to teardown.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('terms screen shows the real terms text', (tester) async {
      await tester.pumpWidget(_wrap(const LegalTextView(document: LegalDocument.terms)));
      await tester.pump();
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.textContaining('RentalHub is a car rental marketplace'), findsOneWidget);
    });

    testWidgets('privacy screen shows the real privacy text', (tester) async {
      await tester.pumpWidget(_wrap(const LegalTextView(document: LegalDocument.privacy)));
      await tester.pump();
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('We do not sell your personal information'), findsOneWidget);
    });
  });

  group('P2-3 city dropdown', () {
    testWidgets('city is a dropdown, not chips, and picking a city moves the pin', (tester) async {
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = _TileHttpOverrides();
      addTearDown(() => HttpOverrides.global = previousOverrides);

      final mapController = MapController();
      var pin = const ll.LatLng(31.5204, 74.3587);
      var city = 'Lahore';
      await tester.pumpWidget(_wrap(ShopLocationStepWidget(
        mapController: mapController,
        shopPin: pin,
        onPinChanged: (p) => pin = p,
        addressController: TextEditingController(),
        selectedCity: city,
        onCityChanged: (c) => city = c,
        majorCities: OwnerOnboardingConstants.majorCities,
        isLocating: false,
        onFetchGps: () {},
      )));
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi').last);
      await tester.pumpAndSettle();

      expect(city, 'Karachi');
      expect(pin.latitude, closeTo(24.8607, 0.001));
      expect(pin.longitude, closeTo(67.0011, 0.001));
    });
  });

  group('P2-4 step-4 validation + Submit for Review', () {
    testWidgets('step 4 without documents blocks Next with field errors', (tester) async {
      await tester.pumpWidget(_wrap(const OwnerOnboardingView(initialStep: 4)));
      await tester.pumpAndSettle();

      expect(find.text('KYC & Verification'), findsOneWidget);
      await tester.tap(find.text('Next Step'));
      await tester.pump();

      // The error names the missing documents; the wizard stays on step 4.
      expect(find.textContaining('is required before submitting'), findsOneWidget);
      expect(find.text('KYC & Verification'), findsOneWidget);
    });

    testWidgets('review step button reads Submit for Review', (tester) async {
      await tester.pumpWidget(_wrap(const OwnerOnboardingView(initialStep: 5)));
      await tester.pumpAndSettle();
      expect(find.text('Submit for Review'), findsOneWidget);
    });
  });

  group('O07 in/out-city day rates', () {
    testWidgets('shows both fields and typing the day rate prefills out-city', (tester) async {
      final rate24 = TextEditingController();
      final outCity = TextEditingController();
      addTearDown(() {
        rate24.dispose();
        outCity.dispose();
      });
      // The rates step is tall (and lives inside the wizard's
      // scrollable step content in production); the standalone pump
      // needs the same scrollable or the Column overflows 600px.
      await tester.pumpWidget(_wrap(SingleChildScrollView(
          child: VehicleRatesStepWidget(
        enable1Hour: true,
        onToggle1Hour: (_) {},
        rate1HourController: TextEditingController(text: '1500'),
        enable3Hours: true,
        onToggle3Hours: (_) {},
        rate3HoursController: TextEditingController(text: '3500'),
        enable6Hours: true,
        onToggle6Hours: (_) {},
        rate6HoursController: TextEditingController(text: '6000'),
        enable24Hours: true,
        onToggle24Hours: (_) {},
        rate24HoursController: rate24,
        enableWeekly: true,
        onToggleWeekly: (_) {},
        rateWeeklyController: TextEditingController(text: '52000'),
        enableMonthly: true,
        onToggleMonthly: (_) {},
        rateMonthlyController: TextEditingController(text: '216000'),
        outCityDayRateController: outCity,
        supportSelfDrive: true,
        onToggleSelfDrive: (_) {},
        supportWithDriver: false,
        onToggleWithDriver: (_) {},
        driverAllowanceController: TextEditingController(),
        securityDepositController: TextEditingController(text: '20000'),
        advanceDepositController: TextEditingController(text: '3000'),
        extraHourChargeController: TextEditingController(text: '600'),
        fuelPolicy: 'Same to Same',
        onFuelPolicyChanged: (_) {},
        fuelPolicies: const ['Same to Same', 'Full to Full'],
      ))));
      await tester.pump();

      expect(find.text('In-City Day Rate'), findsOneWidget);
      expect(find.text('Out-City Day Rate'), findsOneWidget);

      // TextFields in order: 1h, 3h, 6h, 24h, in-city, out-city, ...
      await tester.enterText(find.byType(TextField).at(3), '9000');
      await tester.pump();

      expect(outCity.text, '9000');
      // Shared controller: the 24h row and the in-city row show it too.
      expect(find.text('9000'), findsNWidgets(3));
    });
  });

  group('P4-O06 share with customers', () {
    testWidgets('step 1 picks a price, step 2 shares or copies the link', (tester) async {
      // The test binding never answers Clipboard.setData, so the
      // production copy would await forever and the snackbar would
      // never show. Answer it on the platform channel (other methods
      // pass through with a null reply, as the binding does).
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async => null,
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(_wrap(const OwnerShareWithCustomersView(vehicle: _vehicle)));
      await tester.pump();

      expect(find.text('Share with Customers'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);

      await tester.tap(find.text('Monthly'));
      await tester.pump();
      await tester.tap(find.text('Next Step'));
      await tester.pump();

      expect(find.text('Step 2 of 2'), findsOneWidget);
      expect(find.text('Share Listing'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);
      expect(find.textContaining('rentalhub.62onlinestore.com/vehicle/veh-c-1'), findsOneWidget);
      expect(find.textContaining('Rs. 216,000'), findsOneWidget);

      await tester.tap(find.text('Copy Link'));
      // Copy is async (Clipboard.setData, then the snackbar); a
      // single pump leaves the future pending.
      await tester.pumpAndSettle();
      expect(find.text('Listing link copied'), findsOneWidget);
    });
  });

  group('P4-O07/P4-O09 rate matrix lists', () {
    testWidgets('shows separate In-City and Out-City rate lists', (tester) async {
      await tester.pumpWidget(_wrap(OwnerRateMatrixView(vehicle: _vehicle)));
      await tester.pumpAndSettle();

      expect(find.text('In-City Rent Rates'), findsOneWidget);
      expect(find.text('Out-City Rent Rates'), findsOneWidget);
      // In-city: the duration packages; out-city: day rate + extra-KM.
      expect(find.text('Monthly Package (30 Days)'), findsOneWidget);
      expect(find.text('Out-of-City Daily (24h)'), findsOneWidget);
      expect(find.text('Extra KM Charge'), findsOneWidget);
      expect(find.text('Per KM Pricing?'), findsOneWidget);
      // The editor behaviour is unchanged: custom rates still separate.
      expect(find.text('Custom Rates'), findsOneWidget);
    });
  });
}
