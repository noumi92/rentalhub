import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/manual_bank_transfer_sheet.dart';
import '../services/subscription_data_source.dart';

/// S2 — plan detail (deck p.17 screen 2). Billing-period selector
/// (Monthly / Yearly −17%), trial terms, and "Start 14-day free
/// trial". The trial is requested through the manual bank-transfer
/// flow with a trial note — the trial itself starts only after admin
/// approval; no trial dates are shown until they are stored.
class OwnerSubscriptionPlanDetailView extends StatefulWidget {
  final String planId;

  const OwnerSubscriptionPlanDetailView({super.key, required this.planId});

  @override
  State<OwnerSubscriptionPlanDetailView> createState() =>
      _OwnerSubscriptionPlanDetailViewState();
}

class _OwnerSubscriptionPlanDetailViewState
    extends State<OwnerSubscriptionPlanDetailView> {
  final _dataSource = SubscriptionDataSource();
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

  void _startTrial(SubscriptionPlan plan) {
    final l10n = AppLocalizations.of(context)!;
    ManualBankTransferSheet.show(
      context,
      title: l10n.subscriptionStartTrial,
      amount: plan.priceFor(_yearly),
      note:
          '${l10n.subscriptionPayByBank}\n${l10n.subscriptionTrialNote}',
      onSubmit: (trxId) => _dataSource.submitSubscriptionRequest(
        shopId: currentShopId(),
        tier: plan.id,
        billingPeriod: _yearly ? 'yearly' : 'monthly',
        price: plan.priceFor(_yearly),
        transactionId: trxId,
        isTrial: true,
      ),
      onSubmitted: () =>
          AppFeedback.showSuccess(context, l10n.subscriptionRequested),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = subscriptionPlanFor(widget.planId);
    final isFree = plan.id == 'free';
    final hideExternal =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
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
                  Text(
                    l10n.amountRs(formatRs(plan.monthlyFor(_yearly))),
                    // Audit 2026-11-15 AC-9: headlineMedium is not in
                    // the §4.5 scale — displayLarge (28/Bold) is the
                    // price slot.
                    style: Theme.of(context).textTheme.displayLarge,
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
                                size: 18, color: AppColors.accentSuccessStrong),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(f,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium)),
                          ],
                        ),
                      )),
                  if (!isFree) ...[
                    const SizedBox(height: 16),
                    Text(l10n.subscriptionTrialTerms,
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 16),
                    if (!hideExternal)
                      DebouncedButton(
                        text: l10n.subscriptionStartTrial,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _startTrial(plan),
                      ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                      hideExternal
                          ? l10n.playLaunchPlanIncluded
                          : l10n.subscriptionPlayNotConnectedNote,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(l10n.subscriptionExamplePrices,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
