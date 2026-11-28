import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/owner/presentation/services/subscription_data_source.dart';
import 'package:rentalhub/features/owner/presentation/services/whatsapp_credits_data_source.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_active_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_limit_sheet.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_my_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_plan_detail_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_play_purchase_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_subscription_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_buy_credits_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_credits_added_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_credits_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_history_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_template_preview_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_whatsapp_zero_balance_sheet.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

// Worker E (gated screens S1–S6, W1–W6): the deck screens render
// honest empty/zero states off the Firestore fallback (no Firebase in
// tests) — never the deck's example balances, trial dates, payment
// methods or dispatch rows. Requires the registrar's .arb keys and
// RouteNames constants before it compiles; integration runs it after
// those land.
Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  group('Subscription plans (S1–S3)', () {
    testWidgets('S1 renders the deck chooser, no old prices', (tester) async {
      // The plan cards live in a ListView — give the pump a tall
      // viewport so all three cards are built, as on a real phone
      // after scrolling.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(const OwnerSubscriptionView()));
      await tester.pumpAndSettle();

      expect(find.text('Choose a plan'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('CURRENT PLAN'), findsOneWidget);
      expect(find.text('Coming Soon'), findsNWidgets(2));
      expect(find.textContaining('Upgrade to'), findsNothing);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.textContaining('Save 17%'), findsOneWidget);
      expect(find.text('Example prices — final pricing to be decided'),
          findsOneWidget);
      expect(
          find.text('Google Play billing is not connected yet'), findsNothing);
      // Old manual-plan prices/names are gone.
      expect(find.text('Starter Freemium'), findsNothing);
      expect(find.text('Pro Showroom'), findsNothing);
      expect(find.textContaining('4,999'), findsNothing);
      expect(find.textContaining('12,999'), findsNothing);
      // No fake payment methods anywhere on the chooser.
      expect(find.textContaining('Visa'), findsNothing);
      expect(find.textContaining('4242'), findsNothing);
    });

    testWidgets('S1 Yearly toggle shows the yearly totals', (tester) async {
      await tester.pumpWidget(_wrap(const OwnerSubscriptionView()));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Yearly'));
      await tester.pumpAndSettle();

      expect(find.textContaining('29,990'), findsOneWidget);
    });

    testWidgets('S2 Pro detail shows Coming Soon and hides apply/trial button',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const OwnerSubscriptionPlanDetailView(planId: 'pro')));
      await tester.pumpAndSettle();

      expect(find.text('Start 14-day free trial'), findsNothing);
      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('14-day trial'), findsOneWidget);
      expect(find.textContaining('initial launch'), findsOneWidget);
    });

    testWidgets(
        'S3 purchase sheet hides external bank transfer on Android (Play Payments Policy)',
        (tester) async {
      await tester.pumpWidget(
          _wrap(const OwnerSubscriptionPlayPurchaseView(planId: 'pro')));
      await tester.pumpAndSettle();

      expect(find.text('Google Play billing is not connected yet'),
          findsOneWidget);
      expect(find.textContaining('Visa'), findsNothing);
      expect(find.textContaining('Mastercard'), findsNothing);
      expect(find.textContaining('Pay by bank transfer'), findsNothing);
      expect(find.textContaining('v1.0 launch'), findsOneWidget);
    });
  });

  group('Subscription state (S4–S6)', () {
    testWidgets('S4 shows the real tier and no invented trial dates',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerSubscriptionActiveView()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Current plan: Free'), findsOneWidget);
      expect(find.text('You are on the Free plan'), findsOneWidget);
      expect(find.textContaining('Trial ends'), findsNothing);
      expect(find.textContaining('Next billing date'), findsNothing);
      expect(find.text('No payment method on file'), findsOneWidget);
      expect(find.textContaining('Visa'), findsNothing);
    });

    testWidgets('S5 shows real usage bars and empty billing history',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerSubscriptionMyView()));
      await tester.pumpAndSettle();

      expect(find.text('Cars used'), findsOneWidget);
      expect(find.text('Staff logins'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.text('0 / 1'), findsOneWidget);
      expect(find.text('No subscription payments yet'), findsOneWidget);
      expect(find.text('Manage in Google Play'), findsNothing);
      expect(find.textContaining('initial launch'), findsOneWidget);
    });

    testWidgets(
        'S6 car-limit sheet shows the real cap and Coming Soon notice (no bank transfer)',
        (tester) async {
      await tester.pumpWidget(_wrap(Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => CarLimitSheet.show(context,
                carsUsed: 3, carLimit: 3, planName: 'Free'),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Car limit reached'), findsOneWidget);
      expect(find.text('Upgrade to Business'), findsNothing);
      expect(find.textContaining('Coming Soon'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.textContaining('hidden from listing'), findsOneWidget);
    });

    test('S6 banner trigger: only a real payment issue shows it', () {
      const withIssue = ShopSubscriptionState(
          tier: 'pro', suspended: true, suspensionReason: 'Late payment');
      const clean = ShopSubscriptionState(tier: 'pro');
      expect(withIssue.hasPaymentIssue, isTrue);
      expect(clean.hasPaymentIssue, isFalse);
    });

    test('Plan catalogue: Free cap is the real 3-car limit', () {
      expect(subscriptionPlanFor('basic').carLimit, 3);
      expect(subscriptionPlanFor('pro').carLimit, 10);
      expect(subscriptionPlanFor('enterprise').carLimit, isNull);
      expect(subscriptionPlanFor('enterprise').staffLimit, 5);
      expect(normalizeSubscriptionTier('basic'), 'free');
      expect(normalizeSubscriptionTier('enterprise'), 'business');
    });
  });

  group('WhatsApp credits (W1–W6)', () {
    testWidgets('W1 shows a real zero balance, never the example 84',
        (tester) async {
      // The seven toggles + Buy button live in a ListView — tall
      // viewport so the last toggle is built without scrolling.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(const OwnerWhatsappCreditsView()));
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Messaging — Coming Soon'), findsOneWidget);
      expect(find.text('Credit balance'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No credits yet'), findsOneWidget);
      expect(find.text('84'), findsNothing);
      expect(find.text('Bronze · 50 WhatsApp Credits'), findsOneWidget);
      expect(find.text('Silver · 105 WhatsApp Credits'), findsOneWidget);
      expect(find.text('Gold · 250 WhatsApp Credits'), findsOneWidget);
      expect(find.text('Auto messages'), findsOneWidget);
      expect(find.text('Booking request & approval'), findsOneWidget);
      expect(find.text('Dues reminder'), findsOneWidget);
      expect(find.text('Buy credits'), findsNothing);
    });

    testWidgets('W2 shows packs with Coming Soon and hides buy button',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerWhatsappBuyCreditsView()));
      await tester.pumpAndSettle();

      expect(find.text('WhatsApp Messaging — Coming Soon'), findsOneWidget);
      expect(find.text('Bronze · 50 WhatsApp Credits'), findsOneWidget);
      expect(find.text('Silver · 105 WhatsApp Credits'), findsOneWidget);
      expect(find.text('Gold · 250 WhatsApp Credits'), findsOneWidget);
      expect(find.text('Coming Soon'), findsWidgets);
      expect(find.text('Free plan — 10 messages'), findsOneWidget);
      expect(find.text('Pro plan — 30 credits'), findsOneWidget);
      expect(find.text('Business plan — 100 credits'), findsOneWidget);
      expect(find.text('Buy this pack'), findsNothing);
    });

    testWidgets('W3 request-submitted state is honest, not "added"',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerWhatsappCreditsAddedView(
          requestSubmitted: true, pack: 250, price: 999)));
      await tester.pumpAndSettle();

      expect(find.text('Request submitted'), findsWidgets);
      expect(find.text('Credits will be added after payment verification.'),
          findsOneWidget);
      expect(find.text('Credits added'), findsNothing);
    });

    testWidgets('W3 added state shows only the passed real balances',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerWhatsappCreditsAddedView(
          previousBalance: 0, newBalance: 250, pack: 250, price: 999)));
      await tester.pumpAndSettle();

      expect(find.text('Credits added'), findsWidgets);
      expect(find.text('Previous balance'), findsOneWidget);
      expect(find.text('New balance'), findsOneWidget);
      expect(find.text('334'), findsNothing);
    });

    testWidgets('W4 history is honestly empty with zero counts',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerWhatsappHistoryView()));
      await tester.pumpAndSettle();

      expect(find.text('No WhatsApp messages sent yet'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Receipts'), findsOneWidget);
      expect(find.text('146'), findsNothing);
    });

    testWidgets('W5 template shows placeholders, test send disabled',
        (tester) async {
      await tester.pumpWidget(_wrap(const OwnerWhatsappTemplatePreviewView()));
      await tester.pumpAndSettle();

      expect(find.textContaining('{customerName}'), findsWidgets);
      expect(find.textContaining('{carName}'), findsWidgets);
      expect(find.text('Send test to my number'), findsOneWidget);
      expect(find.text('Available once WhatsApp is connected.'), findsWidgets);
      expect(find.textContaining('Ali Raza'), findsNothing);
    });

    testWidgets('W6 zero-balance sheet offers buy or own WhatsApp',
        (tester) async {
      await tester.pumpWidget(_wrap(Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ZeroBalanceSheet.show(context,
                messagePreview: 'Pickup reminder for booking.',
                customerPhone: '03001234567'),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('No credits left'), findsOneWidget);
      expect(find.text('Buy credits'), findsNothing);
      expect(find.text('Send via my WhatsApp'), findsOneWidget);
      expect(find.text('Pickup reminder for booking.'), findsOneWidget);
    });

    test('W6 banner trigger: only zero balance + a real skip shows it', () {
      expect(WhatsappZeroBalanceBanner.shouldShow(balance: 0, skippedCount: 1),
          isTrue);
      expect(WhatsappZeroBalanceBanner.shouldShow(balance: 5, skippedCount: 1),
          isFalse);
      expect(WhatsappZeroBalanceBanner.shouldShow(balance: 0, skippedCount: 0),
          isFalse);
    });

    test('Credit packs and free allowances match the deck', () {
      expect(
          whatsappCreditPacks.map((p) => p.credits).toList(), [50, 105, 250]);
      expect(whatsappCreditPacks.map((p) => p.price).toList(), [250, 499, 999]);
      expect(whatsappCreditPacks.map((p) => p.name).toList(),
          ['Bronze', 'Silver', 'Gold']);
      expect(whatsappCreditPackForCredits(50)?.name, 'Bronze');
      expect(whatsappCreditPackForCredits(105)?.name, 'Silver');
      expect(whatsappCreditPackForCredits(250)?.name, 'Gold');
      expect(whatsappCreditPackForCredits(999), isNull);
      expect(freeMonthlyCreditsForTier('free'), 10);
      expect(freeMonthlyCreditsForTier('pro'), 30);
      expect(freeMonthlyCreditsForTier('business'), 100);
    });
  });
}
