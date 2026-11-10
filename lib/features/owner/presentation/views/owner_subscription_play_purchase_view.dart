import 'package:flutter/material.dart';

import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/manual_bank_transfer_sheet.dart';
import '../services/subscription_data_source.dart';
import '../../../../core/theme/card_decoration.dart';

/// S3 — Google Play purchase sheet (deck p.17 screen 3), built as an
/// honest not-connected state. The deck shows saved cards and a green
/// Subscribe button; this app has no Play Billing integration and no
/// saved payment methods, so none are shown. The only action offered
/// is the manual bank-transfer flow.
class OwnerSubscriptionPlayPurchaseView extends StatelessWidget {
  final String planId;
  final bool yearly;

  const OwnerSubscriptionPlayPurchaseView({
    super.key,
    required this.planId,
    this.yearly = false,
  });

  String _planName(AppLocalizations l10n, String id) => switch (id) {
        'pro' => l10n.subscriptionPlanPro,
        'business' => l10n.subscriptionPlanBusiness,
        _ => l10n.subscriptionPlanFree,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = subscriptionPlanFor(planId);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.subscriptionPlaySheetTitle,
              subtitle: _planName(l10n, plan.id),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppCardDecoration.shadow(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${_planName(l10n, plan.id)} · ${yearly ? l10n.subscriptionBillingYearly : l10n.subscriptionBillingMonthly}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(l10n.subscriptionPlayTodayFree,
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                            '${l10n.subscriptionPlayThen} · ${l10n.amountRs(formatRs(plan.monthlyFor(yearly)))} ${l10n.subscriptionPerMonth}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(l10n.subscriptionPlayNotConnected,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.subscriptionPlayNotConnectedNote,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DebouncedButton(
                    text: l10n.subscriptionPayByBank,
                    icon: Icons.account_balance_rounded,
                    onPressed: () => ManualBankTransferSheet.show(
                      context,
                      title: l10n.subscriptionUpgradeTo(
                          _planName(l10n, plan.id)),
                      amount: plan.priceFor(yearly),
                      note: l10n.subscriptionPayByBank,
                      onSubmit: (trxId) =>
                          SubscriptionDataSource().submitSubscriptionRequest(
                        shopId: currentShopId(),
                        tier: plan.id,
                        billingPeriod: yearly ? 'yearly' : 'monthly',
                        price: plan.priceFor(yearly),
                        transactionId: trxId,
                        isTrial: false,
                      ),
                      onSubmitted: () => AppFeedback.showSuccess(
                          context, l10n.subscriptionRequested),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(l10n.subscriptionNotNow),
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
