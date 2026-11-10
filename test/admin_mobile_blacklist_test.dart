import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_blacklist_tribunal_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/blacklist_appeal_dialog.dart';
import 'package:rentalhub/features/blacklist/domain/entities/blacklist_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';
import 'test_helper.dart';

// Mobile-first adaptivity (2026-11-10): the tribunal used to build its
// own Row with a fixed 260dp desktop sidebar, leaving ~100px for the
// content at 360px. It now uses the shared AdminShell and stacks the
// status badge under the id line on compact widths.

const _record = AdminBlacklistRecord(
  entity: BlacklistEntity(
    blacklistId: 'BL-123456',
    reportedByShopId: 'shop-1',
    cnicNumber: '35202-1234567-1',
    phoneNumber: '03001234567',
    reasonCategory: 'Unpaid dues',
    description: 'Customer left without settling the final bill.',
  ),
  appealStatus: 'pending',
  appealReason: 'I paid the shop in cash.',
);

Future<void> _pumpTribunal(
  WidgetTester tester, {
  double width = 360,
  double height = 800,
  double textScale = 1.0,
}) async {
  await TestHarness.pumpScreenWithOverflowCheck(
    tester: tester,
    screen: const AdminBlacklistTribunalView(),
    width: width,
    height: height,
    textScale: textScale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  group('admin_mobile_blacklist', () {
    testWidgets('tribunal renders at 360px without overflow',
        (tester) async {
      await _pumpTribunal(tester);
      expect(find.text('Blacklist tribunal'), findsWidgets);
    });

    testWidgets('tribunal renders at 360px with 1.35x text', (tester) async {
      await _pumpTribunal(tester, textScale: 1.35);
      expect(find.text('Blacklist tribunal'), findsWidgets);
    });

    testWidgets('tribunal still renders at desktop width', (tester) async {
      await _pumpTribunal(tester, width: 1280, height: 800);
      expect(find.text('National Rental Fraud & Blacklist Tribunal'),
          findsWidgets);
    });

    testWidgets('appeal dialog fits at 360px', (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: Scaffold(
          body: BlacklistAppealDialog(record: _record, onDecided: () {}),
        ),
        width: 360,
        height: 800,
        textScale: 1.35,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text('Tribunal Blacklist Appeal'), findsOneWidget);
      expect(find.text('Keep flag'), findsOneWidget);
      expect(find.text('Remove flag'), findsOneWidget);
    });

    testWidgets('appeal dialog fits at 360px with 2.0x text',
        (tester) async {
      await TestHarness.pumpScreenWithOverflowCheck(
        tester: tester,
        screen: Scaffold(
          body: BlacklistAppealDialog(record: _record, onDecided: () {}),
        ),
        width: 360,
        height: 800,
        textScale: 2.0,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
      expect(find.text('Remove flag'), findsOneWidget);
    });
  });
}
