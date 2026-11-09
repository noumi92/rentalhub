import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/fleet/domain/entities/vehicle_entity.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_rate_matrix_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/manual_booking_package_selector.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Phone-test round 4, bug 1: the in-city package buttons must be ONE
// horizontal scrolling row — in the 09b rates editor and in the
// walk-in booking package selector — never a Wrap that stacks them.
// The selected chip must stay visible after selection.
const testVehicle = VehicleEntity(
  vehicleId: 'veh-horiz-9b',
  shopId: 'shop-1',
  make: 'Toyota',
  model: 'Corolla GLi',
  year: 2022,
  plateNumber: 'LEA-22-7000',
  rates: VehicleRatesEntity(
    hourly1: 1000,
    hourly3: 2500,
    hourly6: 4000,
    daily24: 7000,
    outOfCityDaily: 9500,
  ),
  weeklyRate: 42000,
  monthlyRate: 168000,
  securityDepositPkr: 25000,
  advanceRequiredPkr: 2000,
  extraHourPkr: 500,
  withDriverSurchargePkr: 1500,
  fuelPolicy: 'Same to Same',
  extraKmPkr: 25,
  outOfCityKmPerDay: 300,
  packages: [
    VehiclePackageEntity(label: '1h', hours: 1, pricePkr: 1000, kmIncluded: 15),
    VehiclePackageEntity(label: '3h', hours: 3, pricePkr: 2500, kmIncluded: 40),
    VehiclePackageEntity(label: '6h', hours: 6, pricePkr: 4000, kmIncluded: 80),
    VehiclePackageEntity(label: '12h', hours: 12, pricePkr: 4200, kmIncluded: 150),
    VehiclePackageEntity(label: '24h', hours: 24, pricePkr: 7000, kmIncluded: 250),
    VehiclePackageEntity(label: 'Weekly', hours: 168, pricePkr: 42000, kmIncluded: 1750),
    VehiclePackageEntity(label: 'Monthly', hours: 720, pricePkr: 168000, kmIncluded: 7500),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  final Finder horizontalRow = find.byWidgetPredicate(
    (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
  );

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OwnerRateMatrixView(vehicle: testVehicle),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpSelector(WidgetTester tester, {ValueChanged<VehiclePackageEntity>? onPick}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: _SelectorHarness(onPick: onPick ?? (_) {})),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool fieldShows(WidgetTester tester, String value) =>
      tester.widgetList<TextField>(find.byType(TextField)).any((f) => f.controller?.text == value);

  /// The chips are one horizontal scrolling row — scroll a far chip
  /// into view before tapping it, or the tap misses.
  Future<void> tapChip(WidgetTester tester, int index) async {
    final finder = find.byType(ChoiceChip).at(index);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Every chip's centre sits on the same horizontal line — a single
  /// row, not two wrapped rows.
  void expectSingleRow(WidgetTester tester) {
    final centers = [for (var i = 0; i < 7; i++) tester.getCenter(find.byType(ChoiceChip).at(i))];
    for (final c in centers) {
      expect(c.dy, closeTo(centers.first.dy, 0.5));
    }
  }

  /// The chip at [index] is fully inside the horizontal row's viewport.
  void expectChipVisibleInRow(WidgetTester tester, int index) {
    final rowRect = tester.getRect(horizontalRow);
    final chipRect = tester.getRect(find.byType(ChoiceChip).at(index));
    expect(chipRect.left, greaterThanOrEqualTo(rowRect.left - 0.5));
    expect(chipRect.right, lessThanOrEqualTo(rowRect.right + 0.5));
  }

  group('09b rates editor — package chips are one horizontal row', () {
    testWidgets('chips sit in a horizontal scrollable row, not a Wrap', (tester) async {
      await pumpEditor(tester);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      expectSingleRow(tester);
      expect(find.ancestor(of: find.byType(ChoiceChip).first, matching: horizontalRow), findsOneWidget);
      expect(find.ancestor(of: find.byType(ChoiceChip).first, matching: find.byType(Wrap)), findsNothing);
      // The row really scrolls: its content is wider than the viewport.
      final scrollable = find.descendant(of: horizontalRow, matching: find.byType(Scrollable));
      expect(tester.state<ScrollableState>(scrollable).position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('tapping Monthly scrolls it into view and selects it', (tester) async {
      await pumpEditor(tester);
      await tapChip(tester, 6);
      expectChipVisibleInRow(tester, 6);
      expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(6)).selected, isTrue);
      expect(fieldShows(tester, '168000'), isTrue);
    });

    testWidgets('tapping back to 1h scrolls it into view and selects it', (tester) async {
      await pumpEditor(tester);
      await tapChip(tester, 6);
      await tapChip(tester, 0);
      expectChipVisibleInRow(tester, 0);
      expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(0)).selected, isTrue);
      expect(fieldShows(tester, '1000'), isTrue);
    });

    testWidgets('switching chips swaps the §1 price and preserves edits', (tester) async {
      await pumpEditor(tester);
      await tapChip(tester, 3);
      expect(fieldShows(tester, '4200'), isTrue);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final priceField = fields.firstWhere((f) => f.controller?.text == '4200');
      await tester.enterText(find.byWidget(priceField), '6000');
      await tester.pumpAndSettle();
      await tapChip(tester, 4);
      expect(fieldShows(tester, '7000'), isTrue);
      await tapChip(tester, 3);
      expect(fieldShows(tester, '6000'), isTrue);
    });
  });

  group('walk-in booking package selector — chips are one horizontal row', () {
    testWidgets('chips sit in a horizontal scrollable row, not a Wrap', (tester) async {
      await pumpSelector(tester);
      expect(find.byType(ChoiceChip), findsNWidgets(7));
      expectSingleRow(tester);
      expect(find.ancestor(of: find.byType(ChoiceChip).first, matching: horizontalRow), findsOneWidget);
      expect(find.ancestor(of: find.byType(ChoiceChip).first, matching: find.byType(Wrap)), findsNothing);
    });

    testWidgets('tapping Monthly scrolls it into view and reports the pick', (tester) async {
      final picked = <VehiclePackageEntity>[];
      await pumpSelector(tester, onPick: picked.add);
      await tapChip(tester, 6);
      expectChipVisibleInRow(tester, 6);
      expect(picked, hasLength(1));
      expect(picked.single.label, 'Monthly');
      expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip).at(6)).selected, isTrue);
    });
  });
}

/// Harness owning the selector's selection, like the walk-in wizard does.
class _SelectorHarness extends StatefulWidget {
  const _SelectorHarness({required this.onPick});

  final ValueChanged<VehiclePackageEntity> onPick;

  @override
  State<_SelectorHarness> createState() => _SelectorHarnessState();
}

class _SelectorHarnessState extends State<_SelectorHarness> {
  VehiclePackageEntity? _selected;

  @override
  void initState() {
    super.initState();
    _selected = testVehicle.packages.firstWhere((p) => p.label == '24h');
  }

  @override
  Widget build(BuildContext context) {
    return ManualBookingPackageSelector(
      vehicle: testVehicle,
      selectedPackage: _selected,
      onPackageChanged: (p) {
        setState(() => _selected = p);
        widget.onPick(p);
      },
      isWithDriver: false,
      onDriverModeChanged: (_) {},
    );
  }
}
