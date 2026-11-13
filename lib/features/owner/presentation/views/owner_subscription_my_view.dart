import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/subscription_data_source.dart';

/// S5 — My subscription (deck p.17 screen 5). Usage bars use REAL
/// counts: fleet size from `vehicles` vs the plan car cap (Free 3,
/// Pro 10, Business unlimited) and staff rows from the `staff`
/// collection vs the plan staff cap (Free 1, Pro 1, Business 5).
/// Billing history is the real `subscription_requests` rows — no fake
/// "Paid" rows. "Manage in Google Play" is honestly disabled until D1.
class OwnerSubscriptionMyView extends StatefulWidget {
  const OwnerSubscriptionMyView({super.key});

  @override
  State<OwnerSubscriptionMyView> createState() =>
      _OwnerSubscriptionMyViewState();
}

class _OwnerSubscriptionMyViewState extends State<OwnerSubscriptionMyView> {
  final _dataSource = SubscriptionDataSource();
  ShopSubscriptionState? _state;
  List<SubscriptionRequestRecord> _history = const [];
  int _fleetCount = 0;
  int _staffCount = 0;
  bool _loaded = false;
  // OW-M8: the load used to have no try/catch — any throw left _loaded false forever and the screen spun indefinitely.
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final shopId = currentShopId();
      final results = await Future.wait([_dataSource.getShopSubscription(shopId), _dataSource.getSubscriptionHistory(shopId), _dataSource.getFleetCount(shopId), _dataSource.getStaffCount(shopId)]);
      if (mounted) {
        setState(() {
          _state = results[0] as ShopSubscriptionState;
          _history = results[1] as List<SubscriptionRequestRecord>;
          _fleetCount = results[2] as int;
          _staffCount = results[3] as int;
          _loaded = true;
        });
      }
    } catch (_) { if (mounted) setState(() => _hasError = true); }
  }

  String _planName(AppLocalizations l10n, String id) => switch (id) {
        'pro' => l10n.subscriptionPlanPro,
        'business' => l10n.subscriptionPlanBusiness,
        _ => l10n.subscriptionPlanFree,
      };

  String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
        'approved' => l10n.subscriptionStatusApproved,
        'rejected' => l10n.subscriptionStatusRejected,
        _ => l10n.subscriptionStatusPending,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _state;
    final plan = subscriptionPlanFor(state?.tier ?? 'free');
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.subscriptionMySubscription,
            ),
            Expanded(
              child: _hasError
                  ? AppErrorState(message: l10n.subscriptionLoadError, onRetry: _load)
                  : !_loaded
                      ? const AppLoadingState()
                      : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      children: [
                        Text(
                          '${_planName(l10n, plan.id)} · ${l10n.amountRs(formatRs(plan.monthlyPrice))} ${l10n.subscriptionPerMonth}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state?.status == 'trial'
                              ? l10n.subscriptionTrialActive
                              : l10n.subscriptionActive,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (state?.nextBillingAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                              '${l10n.subscriptionNextBilling}: ${DateFormat('d MMM yyyy', Localizations.localeOf(context).languageCode).format(state!.nextBillingAt!)}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        // S4 entry point: the active-subscription detail
                        // (trial end / next billing) is reachable from
                        // here while a trial or paid plan is active.
                        if (state?.status == 'trial' ||
                            state?.status == 'active')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => context.push(
                                    RouteNames.ownerSubscriptionActive),
                                child: Text(l10n.subscriptionViewDetails),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _UsageBar(
                          label: l10n.subscriptionCarsUsed,
                          used: _fleetCount,
                          limit: plan.carLimit,
                        ),
                        const SizedBox(height: 12),
                        _UsageBar(
                          label: l10n.subscriptionStaffLogins,
                          used: _staffCount,
                          limit: plan.staffLimit,
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.subscriptionBillingHistory,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (_history.isEmpty)
                          AppEmptyState(
                            title: l10n.subscriptionBillingEmpty,
                            icon: Icons.receipt_long_rounded,
                          )
                        else
                          ..._history.map((row) => Card(
                                child: ListTile(
                                  title: Text(
                                      '${_planName(l10n, row.tier)} · ${row.billingPeriod}'),
                                  subtitle: Text(row.createdAt == null
                                      ? _statusLabel(l10n, row.status)
                                      : '${_statusLabel(l10n, row.status)} · ${DateFormat('d MMM yyyy', Localizations.localeOf(context).languageCode).format(row.createdAt!)}'),
                                  trailing: Text(
                                      l10n.amountRs(formatRs(row.price)),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800)),
                                ),
                              )),
                        const SizedBox(height: 20),
                        DebouncedButton(
                          text: l10n.subscriptionManageInPlay,
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => AppFeedback.showWarning(
                              context, l10n.subscriptionManageInPlayNote),
                        ),
                        Text(l10n.subscriptionManageInPlayNote,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () =>
                                context.push(RouteNames.ownerSubscription),
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

class _UsageBar extends StatelessWidget {
  final String label;
  final int used;
  final int? limit;

  const _UsageBar({
    required this.label,
    required this.used,
    required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final fraction =
        limit == null || limit! <= 0 ? 0.0 : (used / limit!).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(limit == null ? '$used / ∞' : '$used / $limit',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: limit == null ? 0.0 : fraction,
            minHeight: 8,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
