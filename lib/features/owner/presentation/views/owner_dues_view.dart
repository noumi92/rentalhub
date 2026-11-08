import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

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

  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
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
    } catch (_) {} finally {
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
    final message =
        l10n.financeDuesReminderMessage(name, due);
    final uri =
        Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      if (mounted) {
        AppFeedback.showError(context, l10n.financeDuesWhatsappFailed);
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'due_reminder_$customerId', DateTime.now().toIso8601String());
    if (mounted) {
      setState(() => _lastReminded[customerId] = DateTime.now());
      AppFeedback.showSuccess(
          context, l10n.financeDuesReminderSent);
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final groups = _byCustomer;
    final totalDue = _dues.fold(0, (total, b) => total + b.remainingBalance);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              leadingWidget: IconButton(
                tooltip: l10n.back,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.financeDuesTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.financeDuesOutstanding(totalDue),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : groups.isEmpty
                      ? Center(
                          child: Text(l10n.financeDuesEmpty,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = groups.entries.elementAt(index);
                            final bookings = entry.value;
                            final due = bookings.fold(
                                0, (total, b) => total + b.remainingBalance);
                            final name =
                                bookings.first.customerName ?? l10n.requestsCustomerFallback;
                            final phone = bookings.first.customerPhone;
                            final last = _lastReminded[entry.key];
                            final overdue = last == null ||
                                DateTime.now().difference(last).inDays >= 3;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(name,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                      ),
                                      Text(l10n.amountRs(due),
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.dangerTextFor(Theme.of(context).brightness))),
                                    ],
                                  ),
                                  Text(
                                      l10n.financeDuesBookingsLine(bookings.length, phone ?? l10n.financeDuesNoPhone),
                                      style: Theme.of(context).textTheme.labelSmall),
                                  if (last != null)
                                    Text(
                                        l10n.financeDuesLastReminded(last.day, last.month, last.year),
                                        style: Theme.of(context).textTheme.labelSmall),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.chat_rounded,
                                          size: 18),
                                      label: Text(overdue
                                          ? l10n.financeDuesRemind
                                          : l10n.financeDuesRemindAgain),
                                      onPressed: () =>
                                          _remind(entry.key, name, phone, due),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                  l10n.financeDuesAutoNote,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
