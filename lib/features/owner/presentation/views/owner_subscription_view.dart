import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/subscription_data_source.dart';
import '../widgets/dashboard/subscription_tier_card.dart';
import 'owner_subscription_limit_sheet.dart';

/// S1 — Showroom Membership Plans (initial launch phase):
/// Free plan is active for all shops; advanced plans (Pro, Business)
/// show full details with a Coming Soon badge and hidden apply buttons.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 20, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.packagesFreeActiveAllShops,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                          value: false,
                          label: Text(l10n.subscriptionBillingMonthly)),
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
                    final isFree = plan.id == 'free';
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
                            isCurrent: isFree,
                            isPopular: false,
                            isComingSoon: !isFree,
                            showActionButton: false,
                            features: _features(l10n, plan.id),
                            onSelect: () {},
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
