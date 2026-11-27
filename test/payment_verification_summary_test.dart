import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/bookings/domain/entities/booking_entity.dart';
import 'package:rentalhub/features/owner/presentation/widgets/operations/payment_verification_summary.dart';
import 'package:rentalhub/features/trust/data/services/trust_score_service.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// A verified customer who re-submits KYC awaits re-review with
/// status 'resubmitted'. The owner payment-verification screen must
/// show that as a pending submission ("Submitted — pending
/// verification"), never as "Not started" — as if they never
/// submitted KYC at all.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  BookingEntity testBooking() => BookingEntity(
        bookingId: 'RH-PVS-1',
        customerId: 'cust-1',
        shopId: 'shop-1',
        vehicleId: 'veh-1',
        vehicleName: 'Toyota Corolla',
        customerName: 'Ali Raza',
        customerPhone: '03001112233',
        packageType: '24h',
        pickupTime: DateTime.now().subtract(const Duration(days: 1)),
        returnTime: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 21000,
        advanceRequired: 5000,
        advancePaid: 5000,
        remainingBalance: 16000,
        status: 'active',
      );

  TrustScoreResult trustResult(String kycStatus) {
    return TrustScoreResult(
      breakdown: const TrustScoreBreakdown(
        base: 2.5,
        kyc: 1.0,
        trips: 0.5,
        ratings: 0.2,
        punctuality: 0,
        conduct: 0,
        total: 4.2,
      ),
      bookings: const [],
      completedTrips: 3,
      meanOwnerRating: null,
      kycStatus: kycStatus,
    );
  }

  group('PaymentVerificationSummary KYC label', () {
    testWidgets("resubmitted reads as Submitted, never 'Not started'",
        (tester) async {
      await tester.pumpWidget(wrap(PaymentVerificationSummary(
        booking: testBooking(),
        trust: trustResult('resubmitted'),
      )));
      await tester.pumpAndSettle();

      expect(find.text('KYC status: Submitted — pending verification'),
          findsOneWidget);
      expect(find.text('KYC status: Not started'), findsNothing);
    });

    testWidgets('submitted still reads as Submitted', (tester) async {
      await tester.pumpWidget(wrap(PaymentVerificationSummary(
        booking: testBooking(),
        trust: trustResult('submitted'),
      )));
      await tester.pumpAndSettle();

      expect(find.text('KYC status: Submitted — pending verification'),
          findsOneWidget);
    });
  });
}
