/// Deck Step 6 plan catalogue (S1–S6).
///
/// Prices are the deck's example prices (footer: "Example prices —
/// final pricing to be decided"). The Free car cap is 3, not the
/// deck's 2: 3 is the cap `AddVehicleUseCase` really enforces for a
/// Basic-tier shop, so the UI must not promise 2 and enforce 3.
class SubscriptionPlan {
  final String id;
  final int monthlyPrice;
  final int yearlyMonthlyPrice;
  final int yearlyTotal;
  final int? carLimit;
  final int staffLimit;

  const SubscriptionPlan({
    required this.id,
    required this.monthlyPrice,
    required this.yearlyMonthlyPrice,
    required this.yearlyTotal,
    required this.carLimit,
    required this.staffLimit,
  });

  int priceFor(bool yearly) => yearly ? yearlyTotal : monthlyPrice;
  int monthlyFor(bool yearly) => yearly ? yearlyMonthlyPrice : monthlyPrice;
}

const List<SubscriptionPlan> subscriptionPlans = [
  SubscriptionPlan(
    id: 'free',
    monthlyPrice: 0,
    yearlyMonthlyPrice: 0,
    yearlyTotal: 0,
    carLimit: 3,
    staffLimit: 1,
  ),
  SubscriptionPlan(
    id: 'pro',
    monthlyPrice: 2999,
    yearlyMonthlyPrice: 2499,
    yearlyTotal: 29990,
    carLimit: 10,
    staffLimit: 1,
  ),
  SubscriptionPlan(
    id: 'business',
    monthlyPrice: 7999,
    // Deck states no Business yearly price; 17% off the monthly
    // price, the same saving as the deck's Pro yearly figure.
    yearlyMonthlyPrice: 6639,
    yearlyTotal: 79668,
    carLimit: null,
    staffLimit: 5,
  ),
];

SubscriptionPlan subscriptionPlanFor(String tier) =>
    subscriptionPlans.firstWhere(
      (p) => p.id == normalizeSubscriptionTier(tier),
      orElse: () => subscriptionPlans.first,
    );

/// Stored tiers predate the deck names: 'basic' is the Free plan and
/// 'enterprise' is the Business plan. Unknown values fall back to Free.
String normalizeSubscriptionTier(String? raw) {
  switch (raw) {
    case 'pro':
      return 'pro';
    case 'business':
    case 'enterprise':
      return 'business';
    default:
      return 'free';
  }
}
