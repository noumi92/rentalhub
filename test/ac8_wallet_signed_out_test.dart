import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/features/customer/data/services/customer_wallet_service.dart';
import 'package:rentalhub/features/customer/presentation/views/customer_wallet_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

/// AC-8 (UI/UX audit 2026-11-15): the wallet service used to fall
/// back to 'cust-101' when nobody was signed in, so a signed-out
/// wallet read and displayed a stranger's real bookings and
/// deposits. The fallback is gone: [CustomerWalletService.currentUid]
/// is null when signed out, and the view offers sign-in instead.
void main() {
  tearDown(() {
    SignedInUser.override = null;
  });

  test('currentUid is null with nobody signed in', () {
    expect(CustomerWalletService.currentUid(), isNull);
  });

  test('currentUid returns the signed-in uid via the test override', () {
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
    expect(CustomerWalletService.currentUid(), 'cust-101');
  });

  testWidgets('signed-out wallet offers sign-in, never another wallet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CustomerWalletView(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Please sign in to continue.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    // No stranger's money on screen.
    expect(find.textContaining('Rs.'), findsNothing);
  });
}
