import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/subscription_data_source.dart';

/// S2 — Plan detail preview (initial launch phase): displays full plan
/// features and pricing with a Coming Soon badge for advanced plans and
/// hides upgrade/trial application buttons.
class OwnerSubscriptionPlanDetailView extends StatefulWidget {
  final String planId;

  const OwnerSubscriptionPlanDetailView({super.key, required this.planId});

  @override
  State<OwnerSubscriptionPlanDetailView> createState() =>
      _OwnerSubscriptionPlanDetailViewState();
}

class _OwnerSubscriptionPlanDetailViewState
    extends State<OwnerSubscriptionPlanDetailView> {
  bool _yearly = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = subscriptionPlanFor(widget.planId);
    final isFree = plan.id == 'free';
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: _planName(l10n, plan.id),
              subtitle: l10n.subscriptionChoosePlanSubtitle,
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.amountRs(formatRs(plan.monthlyFor(_yearly))),
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFree
                              ? AppColors.accentSuccessStrong
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFree
                              ? l10n.subscriptionCurrentPlan
                              : l10n.packagesComingSoonBadge,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _yearly
                        ? '${l10n.subscriptionPerMonth} · ${l10n.amountRs(formatRs(plan.yearlyTotal))} ${l10n.subscriptionPerYear}'
                        : l10n.subscriptionBilledMonthly,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                          value: false,
                          label: Text(
                              '${l10n.subscriptionBillingMonthly} · ${l10n.amountRs(formatRs(plan.monthlyPrice))}')),
                      ButtonSegment(
                          value: true,
                          label: Text(
                              '${l10n.subscriptionBillingYearly} · ${l10n.subscriptionYearlySave}')),
                    ],
                    selected: {_yearly},
                    onSelectionChanged: (selected) =>
                        setState(() => _yearly = selected.first),
                  ),
                  const SizedBox(height: 16),
                  ..._features(l10n, plan.id).map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 18,
                                color: AppColors.accentSuccessStrong),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(f,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Text(
                    l10n.packagesFreeActiveAllShops,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
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
