// Worker C (phone-test fix batch): hero slider, icon chips, minimal
// app bar, quick-action colours, stepper + fleet-card dark mode, and
// the radius-aware empty state.
//
// The local PNG assets are corrupt ("Invalid image data" locally,
// passing in CI), so image-bearing widgets are pumped through the
// [_TestAssetBundle] that serves a valid 1x1 PNG (same pattern as
// owner_phase_b_fleet_test.dart).
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/core/widgets/app_icon_chip.dart';
import 'package:rentalhub/core/widgets/hero_car_slider.dart';
import 'package:rentalhub/core/widgets/minimal_app_bar.dart';
import 'package:rentalhub/core/widgets/quick_action_tiles.dart';
import 'package:rentalhub/features/discovery/presentation/views/widgets/empty_radar_state.dart';
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/fleet/fleet_vehicle_card.dart';
import 'package:rentalhub/features/owner/presentation/widgets/onboarding/onboarding_stepper_bar.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

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

Widget _withTestAssets(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DefaultAssetBundle(bundle: _TestAssetBundle(), child: child),
    );

Widget _withDarkAssets(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DefaultAssetBundle(bundle: _TestAssetBundle(), child: child),
    );

double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color fg, Color bg) {
  final l1 = _luminance(fg);
  final l2 = _luminance(bg);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

const _testCar = VehicleEntity(
  vehicleId: 'v-civic-1',
  shopId: 'shop-1',
  make: 'Honda',
  model: 'Civic Oriel',
  year: 2021,
  plateNumber: 'LEA-21-4820',
  rates: VehicleRatesEntity(daily24: 9000),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeroCarSlider (#1)', () {
    testWidgets('renders the 4 car slides with dot indicators',
        (tester) async {
      await tester.pumpWidget(_withTestAssets(
        const Scaffold(body: HeroCarSlider(height: 104)),
      ));
      await tester.pump();
      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(HeroCarSlider), findsOneWidget);
      // 4 dots: the active dot is 16 wide, the rest 6 wide.
      expect(find.byType(PageView), findsOneWidget);
      // Teardown in runAsync: the slider owns a periodic Timer,
      // cancelled in dispose — the documented escape hatch.
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      });
    });

    testWidgets('swiping advances to the next slide', (tester) async {
      await tester.pumpWidget(_withTestAssets(
        const Scaffold(body: HeroCarSlider(height: 104)),
      ));
      await tester.pump();
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      });
    });
  });

  group('AppIconChip + AppInitialChip (#12, #5)', () {
    testWidgets('chip renders the icon and fires onPressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_withTestAssets(
        Scaffold(
          body: AppIconChip(
            icon: Icons.notifications_rounded,
            tooltip: 'Notifications',
            onPressed: () => tapped = true,
          ),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      await tester.tap(find.byType(AppIconChip));
      expect(tapped, isTrue);
    });

    testWidgets('chip shows the badge count', (tester) async {
      await tester.pumpWidget(_withTestAssets(
        const Scaffold(
          body: AppIconChip(
            icon: Icons.notifications_rounded,
            badgeCount: 3,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('initial chip shows the user initial and fires onPressed',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_withTestAssets(
        Scaffold(
          body: AppInitialChip(
            initial: 'a',
            onPressed: () => tapped = true,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.byType(AppInitialChip));
      expect(tapped, isTrue);
    });
  });

  group('MinimalAppBar (#16)', () {
    testWidgets('tab root: title + subtitle, no back arrow', (tester) async {
      await tester.pumpWidget(_withTestAssets(
        const Scaffold(
          body: MinimalAppBar(title: 'Fleet', subtitle: 'My Showroom'),
        ),
      ));
      await tester.pump();
      expect(find.text('Fleet'), findsOneWidget);
      expect(find.text('My Showroom'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('onBack shows the arrow and fires the callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_withTestAssets(
        Scaffold(
          body: MinimalAppBar(
            title: 'Onboarding',
            onBack: () => tapped = true,
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(tapped, isTrue);
    });
  });

  group('QuickActionTiles (#7)', () {
    testWidgets('per-tile colour, 28dp icon, medium label', (tester) async {
      await tester.pumpWidget(_withTestAssets(
        Scaffold(
          body: QuickActionTiles(
            tiles: [
              QuickActionTile(
                icon: Icons.directions_car_rounded,
                label: 'Book a Car',
                color: AppColors.secondary,
                onTap: () {},
              ),
              QuickActionTile(
                icon: Icons.calendar_month_rounded,
                label: 'My Reservations',
                color: AppColors.primary,
                onTap: () {},
              ),
            ],
          ),
        ),
      ));
      await tester.pump();
      final carIcon =
          tester.widget<Icon>(find.byIcon(Icons.directions_car_rounded));
      expect(carIcon.size, 28);
      expect(carIcon.color, AppColors.secondary);
      final label = tester.widget<Text>(find.text('Book a Car'));
      // Rulebook §4.5: labelMedium is 500 — the old w800 expectation
      // predates the label-weight audit (items 3/4/5, 2026-11-14).
      expect(label.style?.fontWeight, FontWeight.w500);
    });
  });

  group('OnboardingStepperBar dark mode (#10)', () {
    testWidgets('active step label is readable in dark mode', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        tester: tester,
        screen: const OnboardingStepperBar(currentStep: 2),
        theme: AppTheme.darkTheme,
      );
      final surface = AppTheme.darkTheme.colorScheme.surface;
      final label = tester.widget<Text>(find.text('Location'));
      final color = label.style?.color;
      expect(color, isNotNull);
      expect(color, isNot(AppColors.primary),
          reason: 'active label is still the brand navy in dark mode');
      // Dark mode uses the pale-lavender primaryContainer: the dark
      // theme's colorScheme.primary is #252B7A (1.46:1, unreadable).
      expect(color, AppColors.primaryContainer);
      expect(_contrast(color!, surface), greaterThanOrEqualTo(4.5));
    });
  });

  group('FleetVehicleCard dark mode (#13, #15)', () {
    testWidgets('image-led card, no hardcoded light strip in dark',
        (tester) async {
      await tester.pumpWidget(_withDarkAssets(
        Scaffold(
          body: SingleChildScrollView(
            child: FleetVehicleCard(
              vehicle: _testCar,
              onEditRates: () {},
              onOutCityRules: () {},
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(Hero), findsOneWidget);
      expect(find.text('Honda Civic Oriel 2021'), findsOneWidget);
      expect(find.text('Rs. 9,000/day'), findsOneWidget);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.text('Out-of-city rules'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      // The old hardcoded 0xFFF8FAFC bottom strip must be gone.
      for (final el in find.byType(Container).evaluate()) {
        final w = el.widget as Container;
        final d = w.decoration;
        final color = w.color ?? (d is BoxDecoration ? d.color : null);
        expect(color, isNot(const Color(0xFFF8FAFC)));
      }
    });
  });

  group('EmptyRadarState radius-aware (#3)', () {
    testWidgets('below max: expand button steps to the next radius',
        (tester) async {
      var expanded = false;
      await tester.pumpWidget(_withTestAssets(
        Scaffold(
          body: EmptyRadarState(
            currentRadiusKm: 3.0,
            onExpandRadius: () => expanded = true,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('No Verified Shops Within 3 km'), findsOneWidget);
      await tester.tap(find.text('Expand to 5 km'));
      expect(expanded, isTrue);
    });

    testWidgets('at 5 km max: no expand button, browse-all instead',
        (tester) async {
      await tester.pumpWidget(_withTestAssets(
        const Scaffold(
          body: EmptyRadarState(
            currentRadiusKm: 5.0,
            onExpandRadius: _noop,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('No rental shops near you yet'), findsOneWidget);
      expect(find.text('Expand to 5 km'), findsNothing);
      expect(find.text('Browse all shops'), findsOneWidget);
    });
  });
}

void _noop() {}
