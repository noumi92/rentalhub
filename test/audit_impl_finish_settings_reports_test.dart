// Audit implementation finish tests — worker D (O33 / O37 / PDF title
// + term 2). NOT run here: the integration worker runs this after the
// registrar merges the fragment keys (settingsNotify*, reportDownloadPdf*)
// and regenerates lib/l10n/app_localizations*.dart.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart' as di;
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/finance/utils/report_pdf_generator.dart';
import 'package:rentalhub/features/handover/data/datasources/pdf_contract_generator.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_settings_view.dart';
import 'package:rentalhub/features/owner/presentation/widgets/finance/report_pdf_download_button.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

BookingEntity _booking({
  required String id,
  required DateTime pickup,
  required int amount,
  String status = 'completed',
}) {
  return BookingEntity(
    bookingId: id,
    customerId: 'cust-1',
    shopId: 'shop-1',
    vehicleId: 'veh-1',
    packageType: 'daily',
    pickupTime: pickup,
    returnTime: pickup.add(const Duration(days: 1)),
    totalAmount: amount,
    remainingBalance: 0,
    status: status,
    shopName: 'Test Shop',
  );
}

void main() {
  group('O33 — notification preferences persist (AppSettingsCubit)', () {
    test('all five default to on; a toggle survives a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = AppSettingsCubit(prefs: prefs);
      expect(cubit.state.notifyBookingRequests, isTrue);
      expect(cubit.state.notifyPaymentProofs, isTrue);
      expect(cubit.state.notifyHandover, isTrue);
      expect(cubit.state.notifyReturns, isTrue);
      expect(cubit.state.notifyMaintenance, isTrue);

      await cubit.setNotificationPreference(
          NotificationPreference.paymentProofs, false);
      await cubit.setNotificationPreference(
          NotificationPreference.maintenance, false);
      expect(prefs.getBool('notif_payment_proofs'), isFalse);
      expect(prefs.getBool('notif_maintenance'), isFalse);

      final reloaded = AppSettingsCubit(prefs: prefs);
      expect(reloaded.state.notifyPaymentProofs, isFalse);
      expect(reloaded.state.notifyMaintenance, isFalse);
      expect(reloaded.state.notifyBookingRequests, isTrue);
      expect(reloaded.state.notifyHandover, isTrue);
      expect(reloaded.state.notifyReturns, isTrue);
    });
  });

  group('O33 — notification toggles on the settings screen', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await di.initDependencies();
    });

    testWidgets('five toggles render; tapping one persists it',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: OwnerSettingsView(),
        ),
      );
      await tester.pumpAndSettle();
      // UI/UX audit fix (Team J): the toggles moved into the
      // notifications bottom sheet — open it first.
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      for (final label in [
        'Booking requests',
        'Payment proofs',
        'Handover',
        'Returns',
        'Maintenance reminders',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(SwitchListTile), findsNWidgets(5));

      final tile =
          find.widgetWithText(SwitchListTile, 'Booking requests');
      await tester.tap(find.descendant(
          of: tile, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(sl<SharedPreferences>().getBool('notif_booking_requests'),
          isFalse);
      final reloaded = AppSettingsCubit(prefs: sl<SharedPreferences>());
      expect(reloaded.state.notifyBookingRequests, isFalse);
      // Restore the default so later tests see a clean preference.
      await tester.tap(find.descendant(
          of: tile, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
    });
  });

  group('O37 — report PDF', () {
    test('monthlyRows covers 6 months and counts paid trips only', () {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 5);
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 5);
      final rows = ReportPdfGenerator.monthlyRows([
        _booking(id: 'b1', pickup: thisMonth, amount: 5000),
        _booking(id: 'b2', pickup: thisMonth, amount: 3000, status: 'paid'),
        // Requested trips earn nothing and must not be counted.
        _booking(id: 'b3', pickup: thisMonth, amount: 9999, status: 'requested'),
        _booking(id: 'b4', pickup: twoMonthsAgo, amount: 2000, status: 'active'),
      ]);
      expect(rows, hasLength(6));
      final current = rows.last;
      expect(current.$2, 2);
      expect(current.$3, 8000);
      final old = rows[3];
      expect(old.$2, 1);
      expect(old.$3, 2000);
    });

    test('generateReportPdf produces a real PDF', () async {
      final bytes = await ReportPdfGenerator.generateReportPdf(
        shopName: 'Test Shop',
        periodLabel: 'This month',
        monthlyRows: const [('Jan 2026', 2, 8000)],
        carRows: const [('Corolla — ABC-123', 2, 8000)],
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    testWidgets('download button renders with its tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ReportPdfDownloadButton(
              shopId: 'shop-1',
              period: 'this_month',
              bookings: [_booking(id: 'b1', pickup: DateTime.now(), amount: 5000)],
              carRows: const [('Corolla — ABC-123', 1, 5000)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Download PDF'), findsOneWidget);
    });
  });

  group('PDF title + term 2 — agreement matches the .arb', () {
    test('title is RENTAL AGREEMENT; terms 1, 2, 4–10 match the .arb; '
        'term 3 keeps its deliberate wording', () {
      final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      expect(PdfContractGenerator.agreementTitle, 'RENTAL AGREEMENT');
      expect(PdfContractGenerator.agreementTerms, hasLength(10));
      for (var i = 0; i < 10; i++) {
        if (i == 2) continue; // Term 3: deliberate difference, see below.
        expect(
          PdfContractGenerator.agreementTerms[i],
          arb['contractTerm${i + 1}'],
          reason: 'PDF term ${i + 1} must match the .arb value exactly.',
        );
      }
      // Term 3 is NOT aligned to the .arb — its legal wording awaits
      // the user's own call (audit §4 deliberate difference).
      expect(
        PdfContractGenerator.agreementTerms[2],
        '3. Any default will result in an FIR and a National '
        'Tribunal Blacklist listing.',
      );
      expect(arb['contractTerm3'], isNot('3. Any default will result '
          'in an FIR and a National Tribunal Blacklist listing.'));
    });

    test('generateA4Agreement produces a real PDF', () async {
      final bytes = await PdfContractGenerator.generateA4Agreement(
        agreementId: 'test-1',
        shopName: 'Test Shop',
        customerName: 'Test Customer',
        cnicNumber: '35202-1234567-1',
        customerPhone: '03001234567',
        vehicleDetails: 'Corolla — ABC-123',
        packageType: 'Daily',
        isWithDriver: false,
        pickupTime: DateTime(2026, 11, 9, 10),
        returnTime: DateTime(2026, 11, 10, 10),
        totalAmount: 5000,
        advancePaid: 2000,
        securityDeposit: 10000,
        initialOdometer: 12345,
        fuelLevel: 'Half',
        damageNotes: const [],
      );
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
