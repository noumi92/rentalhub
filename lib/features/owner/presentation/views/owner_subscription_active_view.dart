import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/subscription_data_source.dart';

/// S4 — active subscription (deck p.17 screen 4). Everything shown
/// comes from stored data: `shops.subscriptionTier`, the optional
/// `subscriptionStatus` / `trialEndsAt` / `nextBillingAt` fields, and
/// the latest `subscription_requests` row. No trial end date, billing
/// date, payment method or receipt is shown unless it is actually
/// stored — a shop with no trial simply shows no trial row.
class OwnerSubscriptionActiveView extends StatefulWidget {
  const OwnerSubscriptionActiveView({super.key});

  @override
  State<OwnerSubscriptionActiveView> createState() =>
      _OwnerSubscriptionActiveViewState();
}

class _OwnerSubscriptionActiveViewState
    extends State<OwnerSubscriptionActiveView> {
  final _dataSource = SubscriptionDataSource();
  ShopSubscriptionState? _state;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await _dataSource.getShopSubscription(currentShopId());
    if (mounted) {
      setState(() {
        _state = state;
        _loaded = true;
      });
    }
  }

  String _planName(AppLocalizations l10n, String id) => switch (id) {
        'pro' => l10n.subscriptionPlanPro,
        'business' => l10n.subscriptionPlanBusiness,
        _ => l10n.subscriptionPlanFree,
      };

  String _date(DateTime date) => DateFormat('d MMM yyyy', 'en').format(date);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _state;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.subscriptionMySubscription,
            ),
            Expanded(
              child: !_loaded
                  ? const AppLoadingState()
                  : state == null
                      ? AppErrorState(
                          message: l10n.shopSaveError,
                          onRetry: _load,
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.green, size: 28),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                            '${l10n.subscriptionCurrentTier}: ${_planName(l10n, state.tier)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w900)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.status == 'trial'
                                        ? l10n.subscriptionTrialActive
                                        : state.tier == 'free'
                                            ? l10n.subscriptionFreePlanNote
                                            : l10n.subscriptionActive,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  if (state.trialEndsAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                        '${l10n.subscriptionTrialEnds}: ${_date(state.trialEndsAt!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                  if (state.nextBillingAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                        '${l10n.subscriptionNextBilling}: ${_date(state.nextBillingAt!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                  if (state.pendingTier != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                        '${l10n.subscriptionPendingReview}: ${_planName(l10n, state.pendingTier!)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            ListTile(
                              leading: const Icon(Icons.credit_card_rounded),
                              title: Text(l10n.subscriptionPaymentMethod),
                              subtitle:
                                  Text(l10n.subscriptionNoPaymentMethod),
                            ),
                            Text(l10n.subscriptionReceiptNote,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 16),
                            DebouncedButton(
                              text: l10n.subscriptionGoToDashboard,
                              icon: Icons.dashboard_rounded,
                              onPressed: () =>
                                  context.go(RouteNames.ownerDashboard),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => context.push(
                                    RouteNames.ownerSubscription),
                                child: Text(l10n.subscriptionChangePlan),
                              ),
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
