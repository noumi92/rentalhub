import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rentalhub/core/auth/signed_in_user.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/core/routing/route_names.dart';
import 'package:rentalhub/core/settings/app_settings_cubit.dart';
import 'package:rentalhub/core/theme/app_theme.dart';
import 'package:rentalhub/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/dispute_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/datasources/review_remote_data_source.dart';
import 'package:rentalhub/features/notifications/data/datasources/notification_data_source.dart';
import 'package:rentalhub/features/notifications/presentation/views/customer_notifications_view.dart';
import 'package:rentalhub/features/owner/presentation/views/owner_notifications_view.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    await initDependencies();
    SignedInUser.override = const SignedInUserData(
      uid: 'cust-101',
      displayName: 'Ahmed Raza',
      phoneNumber: '03001234567',
    );
  });

  tearDown(() async {
    SignedInUser.override = null;
    await sl.reset();
  });

  group('In-App Notifications Data Layer & Event Triggers', () {
    test('booking lifecycle emits owner and customer notifications', () async {
      final notifDs = sl<NotificationDataSource>();
      final bookingDs = BookingRemoteDataSource(notifications: notifDs);

      // 1. Customer creates online request -> Owner notified
      final created = await bookingDs.createBookingRequest(
        customerId: 'cust-101',
        shopId: 'shop-1',
        vehicleId: 'v-1',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now().add(const Duration(days: 1)),
        returnTime: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 10000,
        advanceRequired: 2500,
        vehicleName: 'Honda Civic RS',
        shopName: 'Al-Madina Rent a Car',
        customerName: 'Ahmed Raza',
      );

      var shopNotifs = await notifDs.getShopNotifications('shop-1');
      expect(
        shopNotifs.any((n) =>
            n.type == 'booking_request' && n.bookingId == created.bookingId),
        isTrue,
      );

      // 2. Owner approves booking -> Customer notified
      await bookingDs.updateBookingStatus(
        bookingId: created.bookingId,
        status: 'approved',
      );
      var custNotifs = await notifDs.getCustomerNotifications('cust-101');
      expect(
        custNotifs.any((n) =>
            n.type == 'booking_approved' &&
            n.bookingId == created.bookingId &&
            n.recipientRole == 'customer'),
        isTrue,
      );

      // 3. Customer submits payment proof -> Owner notified
      await bookingDs.updatePaymentProof(
        bookingId: created.bookingId,
        paymentProofUrl: 'https://example.com/proof.jpg',
        transactionId: 'TID-999',
      );
      shopNotifs = await notifDs.getShopNotifications('shop-1');
      expect(
        shopNotifs.any((n) =>
            n.type == 'payment_proof' && n.bookingId == created.bookingId),
        isTrue,
      );

      // 4. Owner rejects proof -> Customer notified
      await bookingDs.rejectPaymentProof(
        bookingId: created.bookingId,
        reason: 'Blurry screenshot',
      );
      custNotifs = await notifDs.getCustomerNotifications('cust-101');
      expect(
        custNotifs.any((n) =>
            n.type == 'payment_rejected' &&
            n.body.contains('Blurry screenshot')),
        isTrue,
      );

      // 5. Owner verifies payment -> Customer notified
      await bookingDs.verifyPayment(
        bookingId: created.bookingId,
        advanceAmount: 2500,
      );
      custNotifs = await notifDs.getCustomerNotifications('cust-101');
      expect(
        custNotifs.any((n) =>
            n.type == 'payment_verified' && n.bookingId == created.bookingId),
        isTrue,
      );
    });

    test('customer cancel, dispute, and review notify the shop owner', () async {
      final notifDs = sl<NotificationDataSource>();
      final bookingDs = BookingRemoteDataSource(notifications: notifDs);

      final created = await bookingDs.createBookingRequest(
        customerId: 'cust-101',
        shopId: 'shop-2',
        vehicleId: 'v-2',
        packageType: '24h',
        isWithDriver: false,
        pickupTime: DateTime.now().add(const Duration(days: 1)),
        returnTime: DateTime.now().add(const Duration(days: 2)),
        totalAmount: 8000,
        advanceRequired: 2000,
        vehicleName: 'Toyota Yaris',
        customerName: 'Ahmed Raza',
      );

      await bookingDs.updateBookingStatus(
        bookingId: created.bookingId,
        status: 'cancelled',
        rejectionReason: 'Plans changed',
      );

      await DisputeRemoteDataSource().fileDispute(
        bookingId: created.bookingId,
        customerId: 'cust-101',
        category: 'deposit',
        description: 'Late refund',
        shopId: 'shop-2',
      );

      await ReviewRemoteDataSource().submitCustomerReview(
        bookingId: created.bookingId,
        shopId: 'shop-2',
        customerId: 'cust-101',
        customerName: 'Ahmed Raza',
        vehicleName: 'Toyota Yaris',
        shopRating: 5,
        vehicleRating: 5,
        comment: 'Great car',
      );

      final shopNotifs = await notifDs.getShopNotifications('shop-2');
      expect(shopNotifs.any((n) => n.type == 'booking_cancelled'), isTrue);
      expect(shopNotifs.any((n) => n.type == 'dispute_filed'), isTrue);
      expect(shopNotifs.any((n) => n.type == 'new_review'), isTrue);
    });
  });

  group('CustomerNotificationsView & OwnerNotificationsView UI', () {
    testWidgets(
        'CustomerNotificationsView renders items, filters, marks read, and deep-links',
        (tester) async {
      final notifDs = sl<NotificationDataSource>();
      await notifDs.createCustomerNotification(
        customerId: 'cust-101',
        shopId: 'shop-1',
        title: 'Booking request approved',
        body: 'Pay advance Rs. 2,500 to confirm.',
        type: 'booking_approved',
        bookingId: 'BK-501',
      );

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: RouteNames.customerNotifications,
        routes: [
          GoRoute(
            path: RouteNames.customerNotifications,
            builder: (_, __) =>
                const CustomerNotificationsView(customerId: 'cust-101'),
          ),
          GoRoute(
            path: RouteNames.customerPaymentProof,
            builder: (_, state) {
              pushedRoute = state.uri.toString();
              return const Scaffold(body: Text('Payment proof target'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking request approved'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);

      await tester.tap(find.text('Booking request approved'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/customer/payment/BK-501');
      final after = await notifDs.getCustomerNotifications('cust-101');
      expect(after.first.read, isTrue);
    });

    testWidgets(
        'OwnerNotificationsView renders items, filters, and deep-links payment_proof to ownerPaymentProof',
        (tester) async {
      final notifDs = sl<NotificationDataSource>();
      await notifDs.createNotification(
        shopId: 'shop-1',
        title: 'Payment proof submitted',
        body: 'Ahmed uploaded payment proof for #BK-777',
        type: 'payment_proof',
        bookingId: 'BK-777',
      );

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/owner/notifications',
        routes: [
          GoRoute(
            path: '/owner/notifications',
            builder: (_, __) => const OwnerNotificationsView(shopId: 'shop-1'),
          ),
          GoRoute(
            path: RouteNames.ownerPaymentProof,
            builder: (_, state) {
              pushedRoute = state.uri.toString();
              return const Scaffold(body: Text('Owner verify proof'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment proof submitted'), findsOneWidget);
      await tester.tap(find.text('Payment proof submitted'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/owner/payment/BK-777');
    });

    test('AppSettingsState.isNotificationTypeEnabled respects owner toggles',
        () {
      const state = AppSettingsState(
        notifyBookingRequests: false,
        notifyPaymentProofs: true,
        notifyHandover: false,
        notifyReturns: true,
        notifyMaintenance: false,
      );
      expect(state.isNotificationTypeEnabled('booking_request'), isFalse);
      expect(state.isNotificationTypeEnabled('booking_cancelled'), isFalse);
      expect(state.isNotificationTypeEnabled('payment_proof'), isTrue);
      expect(state.isNotificationTypeEnabled('handover'), isFalse);
      expect(state.isNotificationTypeEnabled('return'), isTrue);
      expect(state.isNotificationTypeEnabled('maintenance'), isFalse);
      expect(state.isNotificationTypeEnabled('dispute_filed'), isTrue);
    });

    testWidgets(
        'CustomerNotificationsView updates live on new arrival and localizes Unread chip in Urdu',
        (tester) async {
      final notifDs = sl<NotificationDataSource>();
      await notifDs.createCustomerNotification(
        customerId: 'cust-101',
        shopId: 'shop-1',
        title: 'First alert',
        body: 'Initial body',
        type: 'booking_approved',
        bookingId: 'BK-801',
      );

      final router = GoRouter(
        initialLocation: RouteNames.customerNotifications,
        routes: [
          GoRoute(
            path: RouteNames.customerNotifications,
            builder: (_, __) =>
                const CustomerNotificationsView(customerId: 'cust-101'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('ur'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First alert'), findsOneWidget);
      expect(find.text('نہ پڑھی گئی'), findsOneWidget);

      // Emit a new notification while inbox is open — should appear live.
      await notifDs.createCustomerNotification(
        customerId: 'cust-101',
        shopId: 'shop-1',
        title: 'Live arrival alert',
        body: 'Arrived while open',
        type: 'payment_verified',
        bookingId: 'BK-802',
      );
      await tester.pumpAndSettle();

      expect(find.text('Live arrival alert'), findsOneWidget);
    });

    testWidgets(
        'OwnerNotificationsView hides Mark all read after marking all read',
        (tester) async {
      final notifDs = sl<NotificationDataSource>();
      await notifDs.createNotification(
        shopId: 'shop-1',
        title: 'New request',
        body: 'Customer requested Civic',
        type: 'booking_request',
        bookingId: 'BK-901',
      );

      final router = GoRouter(
        initialLocation: '/owner/notifications',
        routes: [
          GoRoute(
            path: '/owner/notifications',
            builder: (_, __) => const OwnerNotificationsView(shopId: 'shop-1'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsNothing);
    });
  });
}
