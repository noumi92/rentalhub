import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'owner_vehicle_published_view.dart';

/// Audit §5 finish (P4-O06): share one vehicle with customers.
/// Step 1 of 2 — pick the price to share (Daily / Weekly / Monthly,
/// all read from the vehicle's real packages and rates). Step 2 —
/// review the link and share it or copy it. RQ-F1 (2026-11-13): the
/// step-2 Share / Copy Link actions are DISABLED until the web
/// landing page behind the link exists — the link is the agreed
/// public listing address, not a live page, and the screen says so
/// honestly instead of faking it. (The copy/share helpers live in
/// git history; restore them once the landing page is live.)
class OwnerShareWithCustomersView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerShareWithCustomersView({
    super.key,
    required this.vehicle,
    this.onBack,
  });

  @override
  State<OwnerShareWithCustomersView> createState() =>
      _OwnerShareWithCustomersViewState();
}

class _OwnerShareWithCustomersViewState
    extends State<OwnerShareWithCustomersView> {
  int _step = 1;
  String _period = 'Daily';

  /// OW-m17: null when the package is missing — the UI renders "—"
  /// instead of a confident "Rs. 0" for a price that is unknown.
  int? _priceOf(String label) {
    for (final p in widget.vehicle.effectivePackages) {
      if (p.label == label) return p.pricePkr;
    }
    return null;
  }

  int? get _selectedPrice => switch (_period) {
        'Weekly' => _priceOf('Weekly'),
        'Monthly' => _priceOf('Monthly'),
        _ => widget.vehicle.rates.daily24,
      };

  String _periodLabel(AppLocalizations l10n) => switch (_period) {
        'Weekly' => l10n.ratesCustomPeriodWeekly,
        'Monthly' => l10n.ratesCustomPeriodMonthly,
        _ => l10n.ratesCustomPeriodDaily,
      };

  void _pop() {
    if (_step == 2) {
      setState(() => _step = 1);
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = widget.vehicle;
    final link = OwnerVehiclePublishedView.listingLink(v.vehicleId);
    final periods = <(String, String, int?)>[
      ('Daily', l10n.ratesCustomPeriodDaily, v.rates.daily24),
      ('Weekly', l10n.ratesCustomPeriodWeekly, _priceOf('Weekly')),
      ('Monthly', l10n.ratesCustomPeriodMonthly, _priceOf('Monthly')),
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.shareTitle,
              subtitle: v.displayName,
              onBack: _pop,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                  child: Text(l10n.shareStepOfTwo(_step), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _step == 1
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.shareChoosePrice, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          RadioGroup<String>(
                            groupValue: _period,
                            onChanged: (val) =>
                                setState(() => _period = val ?? 'Daily'),
                            child: Column(
                              children: [
                                ...periods.map((row) {
                                  final key = row.$1;
                                  final selected = _period == key;
                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: selected ? BorderSide(color: Theme.of(context).colorScheme.primary) : BorderSide.none),
                                    child: RadioListTile<String>(
                                      value: key,
                                      title: Text(row.$2, style: Theme.of(context).textTheme.bodyMedium),
                                      subtitle: Text(row.$3 == null ? '—' : l10n.amountRs(formatRs(row.$3!)), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(l10n.shareLinkNote,
                              style: Theme.of(context).textTheme.labelSmall,
                              textAlign: TextAlign.center),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(
                                      '${_periodLabel(l10n)}: ${_selectedPrice == null ? '—' : l10n.amountRs(formatRs(_selectedPrice!))}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.link_rounded, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(link,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(l10n.shareLinkNote,
                              style: Theme.of(context).textTheme.labelSmall,
                              textAlign: TextAlign.center),
                        ],
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor))),
              child: _step == 1
                  ? DebouncedButton(
                      text: l10n.onboardingNextStep,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () async => setState(() => _step = 2),
                    )
                  : Column(
                      children: [
                        // RQ-F1: disabled until the public listing
                        // landing page exists — the link above leads
                        // nowhere yet (see the note on step 2).
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(l10n.vehiclePublishedShareListing),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: Text(l10n.vehiclePublishedCopyLink),
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
