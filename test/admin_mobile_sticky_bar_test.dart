import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_people_data_source.dart';
import 'package:rentalhub/features/admin/domain/trust_score_calculator.dart';
import 'package:rentalhub/features/admin/presentation/views/admin_customer_detail_view.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_shell.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_sticky_action_bar.dart';
import 'package:rentalhub/features/admin/presentation/widgets/kyc_review_detail_body.dart';
import 'package:rentalhub/features/admin/presentation/widgets/shop_detail_actions.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';
import 'package:rentalhub/features/discovery/data/models/shop_model.dart';
import 'package:rentalhub/features/discovery/domain/entities/shop_entity.dart';
import 'package:rentalhub/l10n/app_localizations.dart';

void main() {
  CustomerDetail sampleDetail() => CustomerDetail(
        customer: CustomerEntity(
          customerId: 'cust-1',
          shopId: '',
          name: 'Ayesha Khan',
          phone: '03001234567',
          cnic: '35202-1234567-1',
          source: 'online',
          createdAt: DateTime(2026, 1, 1),
        ),
        storedTrustScore: 5.0,
        trustBreakdown: const TrustScoreBreakdown(
          base: 5.0,
          kyc: 0,
          trips: 0,
          ratings: 0,
          punctuality: 0,
          conduct: 0,
          total: 5.0,
        ),
        blacklistRecord: null,
        bookings: const [],
        completedTrips: 2,
        meanOwnerRating: 4.8,
        notes: const [],
        isWatchlisted: false,
        isBlacklisted: false,
        kycStatus: 'verified',
      );

  const sampleShop = ShopModel(
    shopId: 'shop-1',
    ownerId: 'owner-1',
    shopName: 'Lahore Motors',
    ownerName: 'Usman Ali',
    city: 'Lahore',
    address: 'Main Blvd',
    phoneNumber: '03001234567',
    geoLocation: GeoPointEntity(31.5204, 74.3587),
    bankAccounts: [],
    rating: 4.5,
    isVerified: true,
    verificationStatus: 'approved',
  );

  Widget wrapMobile(Widget child) {
    return MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets(
      'AdminCustomerDetailView on mobile shows tabs and body above compact sticky bar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapMobile(
        AdminCustomerDetailView(
          customerId: 'cust-1',
          loadDetail: (_) async => sampleDetail(),
          resolveAdminRole: () async => 'super_admin',
          loadQrCode: (_) async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    final barSize = tester.getSize(find.byType(AdminStickyActionBar));
    expect(barSize.height, lessThan(220));
    final bodySize = tester.getSize(find.byType(TabBarView));
    expect(bodySize.height, greaterThan(200));
  });

  testWidgets(
      'AdminShell mobile sticky bar stays compact for ShopDetailActions and KycDecisionButtons',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapMobile(
        AdminShell(
          activeRoute: '/admin/shops',
          title: 'Shop Detail',
          subtitle: 'Sub',
          bottomBar: ShopDetailActions(
            shop: sampleShop,
            isWorking: false,
            onToggleSuspend: () {},
            onReviewApplication: () {},
          ),
          child: const Center(child: Text('Shop Body Visible')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shop Body Visible'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AdminStickyActionBar)).height,
      lessThan(260),
    );

    await tester.pumpWidget(
      wrapMobile(
        AdminShell(
          activeRoute: '/admin/kyc-review',
          title: 'KYC Detail',
          subtitle: 'Sub',
          bottomBar: KycDecisionButtons(
            isWorking: false,
            onDecide: (_) async {},
          ),
          child: const Center(child: Text('KYC Body Visible')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KYC Body Visible'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AdminStickyActionBar)).height,
      lessThan(220),
    );
  });
}
