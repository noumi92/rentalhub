import 'package:flutter/material.dart';

import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../services/subscription_data_source.dart';
import '../services/whatsapp_credits_data_source.dart';

/// W4 — Message history (deck p.19 screen 4). Stats and rows come
/// only from the real `whatsapp_dispatch_logs` collection — today
/// that collection is empty, so the honest empty state renders and
/// all three counts are 0. Filter chips: All / Bookings / Reminders /
/// Receipts. No fake rows, no example counts.
class OwnerWhatsappHistoryView extends StatefulWidget {
  const OwnerWhatsappHistoryView({super.key});

  @override
  State<OwnerWhatsappHistoryView> createState() =>
      _OwnerWhatsappHistoryViewState();
}

class _OwnerWhatsappHistoryViewState extends State<OwnerWhatsappHistoryView> {
  final _credits = WhatsappCreditsDataSource();
  final _subs = SubscriptionDataSource();
  String _filter = 'all';
  List<WhatsappDispatchLog> _logs = const [];
  int _freeCredits = 10;
  bool _loaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final shopId = currentShopId();
      final logs = await _credits.getDispatchLogs(shopId, category: _filter);
      final state = await _subs.getShopSubscription(shopId);
      if (mounted) {
        setState(() {
          _logs = logs;
          _freeCredits = freeMonthlyCreditsForTier(state.tier);
          _loaded = true;
          _hasError = false;
        });
      }
    } catch (e) {
      // A failed load used to spin forever — render the error
      // state with retry instead.
      debugPrint('OwnerWhatsappHistoryView load failed: $e'); // Audit 2026-11-15 DS-6: raw error logged; user sees only the localized per-screen message.
      if (mounted) {
        setState(() {
          _loaded = true;
          _hasError = true;
        });
      }
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
      _loaded = false;
      _hasError = false;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sent = _logs.length;
    final delivered =
        _logs.where((e) => e.status == 'delivered' || e.status == 'read').length;
    final read = _logs.where((e) => e.status == 'read').length;
    final chips = <({String id, String label})>[
      (id: 'all', label: l10n.creditsFilterAll),
      (id: 'bookings', label: l10n.creditsFilterBookings),
      (id: 'reminders', label: l10n.creditsFilterReminders),
      (id: 'receipts', label: l10n.creditsFilterReceipts),
    ];
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.creditsHistoryTitle,
              subtitle: l10n.creditsTitle,
            ),
            Expanded(
              child: !_loaded
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.whatsappHistoryLoadError,
                          onRetry: _load,
                        )
                      : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      children: [
                        Row(
                          children: [
                            Expanded(child: _Stat(label: l10n.creditsSent, value: sent)),
                            Expanded(child: _Stat(label: l10n.creditsDelivered, value: delivered)),
                            Expanded(child: _Stat(label: l10n.creditsRead, value: read)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: chips
                                .map((c) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(c.label),
                                        selected: _filter == c.id,
                                        onSelected: (_) => _setFilter(c.id),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_logs.isEmpty)
                          AppEmptyState(
                            title: l10n.creditsHistoryEmpty,
                            icon: Icons.chat_bubble_rounded,
                          )
                        else
                          ..._logs.map((log) => Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.chat_bubble_rounded,
                                        size: 18),
                                  ),
                                  title: Text(log.recipientName.isEmpty
                                      ? log.phone
                                      : log.recipientName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      // Audit 2026-11-15 DS-5: localized day + time, never a hardcoded-'en' format.
                                      '${log.messageType} · ${log.sentAt == null ? '' : formatDayTime(context, log.sentAt!)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Text(log.status,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w500)),
                                ),
                              )),
                        const SizedBox(height: 12),
                        Text(
                          '${l10n.creditsUsedLabel}: $sent · ${l10n.creditsFreeLabel}: $_freeCredits',
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

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        // Urdu labels wrap to two lines at 360px instead of
        // overflowing the row.
        Text(label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
