import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/dashboard/subscription_tier_card.dart';
import '../widgets/manual_bank_transfer_sheet.dart';
import 'owner_subscription_limit_sheet.dart';
import '../services/subscription_data_source.dart';

/// S1 — Choose a plan (deck p.17 screen 1). Gated on D1 (Play Console):
/// the deck's Monthly/Yearly picker and prices are built, but Google
/// Play billing is NOT connected — Subscribe opens the existing manual
/// bank-transfer flow, the only payment path. The current tier is read
/// from the real `shops` doc, never hardcoded.
class OwnerSubscriptionView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerSubscriptionView({super.key, this.onBack});

  @override
  State<OwnerSubscriptionView> createState() => _OwnerSubscriptionViewState();
}

class _OwnerSubscriptionViewState extends State<OwnerSubscriptionView> {
  final _dataSource = SubscriptionDataSource();
  bool _yearly = false;
  ShopSubscriptionState _state = const ShopSubscriptionState(tier: 'free');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await _dataSource.getShopSubscription(currentShopId());
    if (mounted) setState(() => _state = state);
  }

  String _planName(AppLocalizations l10n, String id) => switch (id) {
        'pro' => l10n.subscriptionPlanPro,
        'business' => l10n.subscriptionPlanBusiness,
        _ => l10n.subscriptionPlanFree,
      };

  List<String> _features(AppLocalizations l10n, String id) => switch (id) {
        'pro' => [
            l10n.subscriptionProCars,
            l10n.subscriptionProKyc,
            l10n.subscriptionProStamp,
            l10n.subscriptionProAccounts,
            l10n.subscriptionProListing,
            l10n.subscriptionProTrial,
          ],
        'business' => [
            l10n.subscriptionBusinessCars,
            l10n.subscriptionBusinessStaff,
            l10n.subscriptionBusinessReports,
            l10n.subscriptionBusinessExport,
            l10n.subscriptionBusinessBadge,
            l10n.subscriptionBusinessSupport,
          ],
        _ => [
            l10n.subscriptionFreeCars,
            l10n.subscriptionFreeBookings,
            l10n.subscriptionFreeBranding,
            l10n.subscriptionFreeLogins,
          ],
      };

  void _subscribe(SubscriptionPlan plan) {
    final l10n = AppLocalizations.of(context)!;
    ManualBankTransferSheet.show(
      context,
      title: l10n.subscriptionUpgradeTo(_planName(l10n, plan.id)),
      amount: plan.priceFor(_yearly),
      note: l10n.subscriptionPayByBank,
      onSubmit: (trxId) => _dataSource.submitSubscriptionRequest(
        shopId: currentShopId(),
        tier: plan.id,
        billingPeriod: _yearly ? 'yearly' : 'monthly',
        price: plan.priceFor(_yearly),
        transactionId: trxId,
        isTrial: false,
      ),
      onSubmitted: () {
        setState(() => _state = ShopSubscriptionState(
              tier: _state.tier,
              status: _state.status,
              trialEndsAt: _state.trialEndsAt,
              nextBillingAt: _state.nextBillingAt,
              suspended: _state.suspended,
              suspensionReason: _state.suspensionReason,
              pendingTier: plan.id,
            ));
        AppFeedback.showSuccess(context, l10n.subscriptionRequested);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hideExternal =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.subscriptionChoosePlanTitle,
              subtitle: l10n.subscriptionChoosePlanSubtitle,
              onBack: widget.onBack,
              actions: [
                IconButton(
                  tooltip: l10n.subscriptionMySubscription,
                  icon: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white),
                  onPressed: () =>
                      context.push(RouteNames.ownerSubscriptionMy),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  if (_state.hasPaymentIssue) ...[
                    SubscriptionPaymentIssueBanner(
                        reason: _state.suspensionReason),
                    const SizedBox(height: 14),
                  ],
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                          value: false, label: Text(l10n.subscriptionBillingMonthly)),
                      ButtonSegment(
                          value: true,
                          label: Text(
                              '${l10n.subscriptionBillingYearly} · ${l10n.subscriptionYearlySave}')),
                    ],
                    selected: {_yearly},
                    onSelectionChanged: (selected) =>
                        setState(() => _yearly = selected.first),
                  ),
                  const SizedBox(height: 14),
                  ...subscriptionPlans.map((plan) {
                    final isCurrent =
                        normalizeSubscriptionTier(_state.tier) == plan.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SubscriptionTierCard(
                            title: _planName(l10n, plan.id),
                            pricePkr: plan.priceFor(_yearly),
                            billingPeriod: _yearly
                                ? l10n.subscriptionPerYear
                                : l10n.subscriptionPerMonth,
                            isCurrent: isCurrent,
                            isPopular: plan.id == 'pro',
                            isPending:
                                _state.pendingTier == plan.id ||
                                    (_state.pendingTier != null &&
                                        normalizeSubscriptionTier(
                                                _state.pendingTier) ==
                                            plan.id),
                            features: _features(l10n, plan.id),
                            onSelect: () => (plan.id == 'free' || hideExternal)
                                ? context.push(
                                    RouteNames.ownerSubscriptionPlan,
                                    extra: plan.id)
                                : _subscribe(plan),
                          ),
                          if (plan.id != 'free')
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push(
                                    RouteNames.ownerSubscriptionPlan,
                                    extra: plan.id),
                                child: Text(l10n.subscriptionViewDetails),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  Text(
                    l10n.subscriptionExamplePrices,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.subscriptionPlayNotConnectedNote,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
