// RQ-F3 (2026-11-13): the manual bank-transfer subscription flow
// writes to `subscription_requests` and the admin side reads it back.
// These tests pin the write + read-back against FakeFirebaseFirestore
// (same pattern as test/shop_id_resolution_test.dart) — the write
// path itself, not just the fleet-count helper that already had a
// test. The cPanel upload / API-key / public-read-rules steps stay
// manual (see the rulebook §13 D-note for RQ-F3); no phone test.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentalhub/features/owner/presentation/services/subscription_data_source.dart';

void main() {
  late FakeFirebaseFirestore fake;
  late SubscriptionDataSource ds;

  setUp(() {
    fake = FakeFirebaseFirestore();
    ds = SubscriptionDataSource(firestore: fake);
  });

  test('submitSubscriptionRequest writes a pending request', () async {
    await ds.submitSubscriptionRequest(
      shopId: 'shop_test-1',
      tier: 'pro',
      billingPeriod: 'monthly',
      price: 2999,
      transactionId: 'TRX-12345',
      isTrial: false,
    );

    final snap =
        await fake.collection('subscription_requests').get();
    expect(snap.docs, hasLength(1));
    final data = snap.docs.single.data();
    expect(data['shopId'], 'shop_test-1');
    expect(data['tier'], 'pro');
    expect(data['billingPeriod'], 'monthly');
    expect(data['price'], 2999);
    expect(data['transactionId'], 'TRX-12345');
    expect(data['isTrial'], isFalse);
    expect(data['status'], 'pending');
    expect(data['createdAt'], isNotNull);
  });

  test('submitted request reads back via getSubscriptionHistory', () async {
    await ds.submitSubscriptionRequest(
      shopId: 'shop_test-1',
      tier: 'business',
      billingPeriod: 'yearly',
      price: 7999,
      transactionId: 'TRX-99999',
      isTrial: true,
    );

    final history = await ds.getSubscriptionHistory('shop_test-1');
    expect(history, hasLength(1));
    expect(history.single.tier, 'business');
    expect(history.single.billingPeriod, 'yearly');
    expect(history.single.price, 7999);
    expect(history.single.transactionId, 'TRX-99999');
    expect(history.single.status, 'pending');
  });

  test('history is scoped to the requesting shop', () async {
    await ds.submitSubscriptionRequest(
      shopId: 'shop_test-1',
      tier: 'pro',
      billingPeriod: 'monthly',
      price: 2999,
      transactionId: 'TRX-11111',
      isTrial: false,
    );
    await ds.submitSubscriptionRequest(
      shopId: 'shop_test-2',
      tier: 'pro',
      billingPeriod: 'monthly',
      price: 2999,
      transactionId: 'TRX-22222',
      isTrial: false,
    );

    final history = await ds.getSubscriptionHistory('shop_test-1');
    expect(history, hasLength(1));
    expect(history.single.transactionId, 'TRX-11111');
    expect(await ds.getSubscriptionHistory('shop_test-2'),
        hasLength(1));
  });

  test('pending request surfaces as pendingTier on the shop state',
      () async {
    await ds.submitSubscriptionRequest(
      shopId: 'shop_test-1',
      tier: 'pro',
      billingPeriod: 'monthly',
      price: 2999,
      transactionId: 'TRX-12345',
      isTrial: false,
    );

    final state = await ds.getShopSubscription('shop_test-1');
    expect(state.pendingTier, 'pro');
  });
}
