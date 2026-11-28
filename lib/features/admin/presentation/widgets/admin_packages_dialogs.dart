import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_packages_data_source.dart';

class PlanChangeResult {
  const PlanChangeResult({required this.tier, required this.reason});
  final String tier;
  final String reason;
}

class CreditsAdjustResult {
  const CreditsAdjustResult({required this.delta, required this.reason});
  final int delta;
  final String reason;
}

Future<PlanChangeResult?> showAdminChangePlanDialog(
  BuildContext context, {
  required AdminShopPlanRow shop,
}) async {
  final l10n = AppLocalizations.of(context);
  var selected = shop.tier;
  final reasonCtrl = TextEditingController();
  final result = await showDialog<PlanChangeResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        scrollable: true,
        title: Text(
          '${l10n?.adminPackagesChangePlan ?? 'Change Plan'} — ${shop.shopName}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.adminPackagesSelectPlan ?? 'Select plan tier'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final tier in const ['free', 'pro', 'business'])
                  ChoiceChip(
                    label: Text(tier.toUpperCase()),
                    selected: selected == tier,
                    onSelected: (_) => setDialog(() => selected = tier),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: l10n?.adminPackagesReasonHint ?? 'Optional note',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(
              PlanChangeResult(tier: selected, reason: reasonCtrl.text.trim()),
            ),
            child: Text(l10n?.commonConfirm ?? 'Confirm'),
          ),
        ],
      ),
    ),
  );
  reasonCtrl.dispose();
  return result;
}

Future<CreditsAdjustResult?> showAdminGrantCreditsDialog(
  BuildContext context, {
  required AdminShopPlanRow shop,
}) async {
  final l10n = AppLocalizations.of(context);
  final deltaCtrl = TextEditingController(text: '100');
  final reasonCtrl = TextEditingController();
  final result = await showDialog<CreditsAdjustResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(
        '${l10n?.adminPackagesGrantCredits ?? 'Grant Credits'} — ${shop.shopName}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: deltaCtrl,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: l10n?.adminPackagesCreditsDeltaLabel ??
                  'Credits to add (or negative to deduct)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(
              hintText: l10n?.adminPackagesReasonHint ?? 'Optional note',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = int.tryParse(deltaCtrl.text.trim()) ?? 0;
            if (parsed == 0) return;
            Navigator.of(ctx).pop(
              CreditsAdjustResult(
                delta: parsed,
                reason: reasonCtrl.text.trim(),
              ),
            );
          },
          child: Text(l10n?.commonConfirm ?? 'Confirm'),
        ),
      ],
    ),
  );
  deltaCtrl.dispose();
  reasonCtrl.dispose();
  return result;
}

Future<String?> showAdminReasonDialog(
  BuildContext context, {
  required String title,
}) async {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text('${l10n?.adminPackagesRejectRequest ?? 'Reject'} — $title'),
      content: TextField(
        controller: ctrl,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: l10n?.adminPackagesReasonHint ?? 'Rejection reason',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          child: Text(l10n?.commonConfirm ?? 'Confirm'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}
