import 'package:flutter/material.dart';

import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/manual_bank_transfer_sheet.dart';
import '../services/subscription_data_source.dart';

/// S6 — car-limit sheet + payment-issue banner (deck p.17 screen 6).
///
/// The sheet appears only when the shop really hits its plan car cap
/// (Free 3 — the `AddVehicleUseCase` limit; Pro 10; Business
/// unlimited). The banner appears only when a real payment issue
/// exists (shop suspended / `suspensionReason` set, or a rejected
/// subscription request). Neither is ever shown on made-up state.
///
/// S6 nav decision (audit §2 nav flag): the deck shows the fleet list
/// behind the sheet WITH the bottom nav visible, but the app's rule is
/// that a sheet over a fleet sub-screen hides the nav. This sheet
/// mounts over the fleet view as a modal bottom sheet, so the tab bar
/// is hidden while it is open — the app rule wins over the deck
/// drawing. Integration wires the mount point in the fleet view;
/// this file only owns the sheet + banner widgets.
class SubscriptionPaymentIssueBanner extends StatelessWidget {
  final String? reason;

  const SubscriptionPaymentIssueBanner({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.subscriptionPaymentIssue,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.subscriptionPaymentIssueBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer)),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(reason!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
          ],
        ],
      ),
    );
  }
}

class CarLimitSheet {
  CarLimitSheet._();

  /// Shows the car-limit sheet. [carsUsed] and [carLimit] are the real
  /// fleet count and the current plan's cap; callers only call this
  /// when `carsUsed >= carLimit`.
  static Future<void> show(
    BuildContext context, {
    required int carsUsed,
    required int carLimit,
    required String planName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final business = subscriptionPlanFor('business');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.subscriptionCarLimitTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(l10n.subscriptionCarLimitBody(planName, '$carLimit'),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _UsageBar(used: carsUsed, limit: carLimit),
            const SizedBox(height: 8),
            Text(l10n.subscriptionDowngradeNote,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            DebouncedButton(
              text: l10n.subscriptionUpgradeToBusiness,
              icon: Icons.workspace_premium_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                ManualBankTransferSheet.show(
                  context,
                  title: l10n.subscriptionUpgradeToBusiness,
                  amount: business.monthlyPrice,
                  note: l10n.subscriptionPayByBank,
                  onSubmit: (trxId) => SubscriptionDataSource()
                      .submitSubscriptionRequest(
                    shopId: currentShopId(),
                    tier: 'business',
                    billingPeriod: 'monthly',
                    price: business.monthlyPrice,
                    transactionId: trxId,
                    isTrial: false,
                  ),
                  onSubmitted: () => AppFeedback.showSuccess(
                      context, l10n.subscriptionRequested),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.subscriptionNotNow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final int used;
  final int limit;

  const _UsageBar({required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final fraction = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$used / $limit',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
