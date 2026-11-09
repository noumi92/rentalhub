import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/owner_dues_group_card.dart';
import '../../../../core/utils/money_format.dart';

/// Phase B (H3): what customers still owe. A due is a booking
/// whose balance is unpaid — the advance on an approved booking,
/// or the rest on a paid or finished trip. The owner can remind a
/// customer on WhatsApp by hand today (a wa.me link with the
/// message ready); automated reminders wait for the WhatsApp
/// Business setup (Phase I, gate D2).
class OwnerDuesView extends StatefulWidget {
  final String shopId;

  const OwnerDuesView({super.key, this.shopId = 'shop-1'});

  @override
  State<OwnerDuesView> createState() => _OwnerDuesViewState();
}

class _OwnerDuesViewState extends State<OwnerDuesView> {
  List<BookingEntity> _dues = [];
  Map<String, DateTime> _lastReminded = {};
  bool _isLoading = true;
  bool _hasError = false;

  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final bookings =
          await sl<BookingRemoteDataSource>().getShopBookings(widget.shopId);
      final prefs = await SharedPreferences.getInstance();
      final reminded = <String, DateTime>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('due_reminder_')) continue;
        final raw = prefs.getString(key);
        final when = raw == null ? null : DateTime.tryParse(raw);
        if (when != null) {
          reminded[key.substring('due_reminder_'.length)] = when;
        }
      }
      if (mounted) {
        setState(() {
          _dues = bookings
              .where((b) =>
                  _dueStatuses.contains(b.status) && b.remainingBalance > 0)
              .toList()
            ..sort((a, b) => b.remainingBalance.compareTo(a.remainingBalance));
          _lastReminded = reminded;
        });
      }
    } catch (_) {
      // Audit §25/C4: a failed load used to render as "no dues".
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<BookingEntity>> get _byCustomer {
    final map = <String, List<BookingEntity>>{};
    for (final b in _dues) {
      map.putIfAbsent(b.customerId, () => []).add(b);
    }
    return map;
  }

  String _waNumber(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) return digits;
    if (digits.startsWith('0')) return '92${digits.substring(1)}';
    return digits;
  }

  Future<void> _remind(
      String customerId, String name, String? phone, int due) async {
    final l10n = AppLocalizations.of(context)!;
    final number = _waNumber(phone);
    if (number.isEmpty) {
      AppFeedback.showError(context, l10n.financeDuesNoPhoneError);
      return;
    }
    final message = l10n.financeDuesReminderMessage(name, formatRs(due));
    final uri =
        Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (mounted) {
        AppFeedback.showError(context, l10n.financeDuesWhatsappFailed);
      }
      return;
    }
    // Audit §25: opening WhatsApp is not sending. The 3-day
    // "remind again" clock starts only when the owner confirms
    // the message was actually sent from the chat.
    if (!mounted) return;
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.financeDuesRemind),
        content: Text(l10n.financeDuesReminderSent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonGoBack),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (sent != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'due_reminder_$customerId', DateTime.now().toIso8601String());
    if (mounted) {
      setState(() => _lastReminded[customerId] = DateTime.now());
      AppFeedback.showSuccess(context, l10n.financeDuesReminderSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = _byCustomer;
    final totalDue = _dues.fold(0, (total, b) => total + b.remainingBalance);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.financeDuesTitle,
              subtitle: l10n.financeDuesOutstanding(formatRs(totalDue)),
              onBack: () => context.pop(),
            ),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.bookingsLoadError,
                          onRetry: _load,
                        )
                      : groups.isEmpty
                          ? AppEmptyState(
                              title: l10n.financeDuesEmpty,
                              icon: Icons.handshake_rounded,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              itemCount: groups.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                // Audit §25: the total due was only a
                                // 12sp app-bar subtitle that truncated
                                // — it gets a summary card at the top.
                                if (index == 0) {
                                  return DuesTotalCard(totalDue: totalDue);
                                }
                                final entry =
                                    groups.entries.elementAt(index - 1);
                                final bookings = entry.value;
                                final due = bookings.fold(
                                    0,
                                    (total, b) =>
                                        total + b.remainingBalance);
                                // Audit impl (worker C, O46): tapping
                                // a customer group opens that customer's
                                // statement.
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => context.push(
                                    RouteNames.ownerCustomerStatement
                                        .replaceFirst(
                                            ':customerId', entry.key),
                                  ),
                                  child: DuesGroupCard(
                                    bookings: bookings,
                                    lastReminded: _lastReminded[entry.key],
                                    onRemind: () => _remind(
                                      entry.key,
                                      bookings.first.customerName ??
                                          l10n.requestsCustomerFallback,
                                      bookings.first.customerPhone,
                                      due,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(l10n.financeDuesAutoNote,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
