import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// S6 — car-limit sheet + payment-issue banner.
/// During initial launch, paid upgrades are Coming Soon so the sheet never
/// opens an external bank-transfer checkout.
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onErrorContainer)),
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

  /// Shows the car-limit sheet when `carsUsed >= carLimit`.
  static Future<void> show(
    BuildContext context, {
    required int carsUsed,
    required int carLimit,
    required String planName,
  }) async {
    final l10n = AppLocalizations.of(context)!;
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
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(l10n.subscriptionCarLimitBody(planName, '$carLimit'),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _UsageBar(used: carsUsed, limit: carLimit),
            const SizedBox(height: 8),
            Text(l10n.subscriptionDowngradeNote,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              '${l10n.packagesComingSoonBadge}: ${l10n.packagesFreeActiveAllShops}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
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
                ?.copyWith(fontWeight: FontWeight.w500)),
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
