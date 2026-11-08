import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../widgets/dashboard/whatsapp_log_tile.dart';

class OwnerWhatsAppLogsView extends StatefulWidget {
  final VoidCallback? onBack;

  const OwnerWhatsAppLogsView({super.key, this.onBack});

  @override
  State<OwnerWhatsAppLogsView> createState() => _OwnerWhatsAppLogsViewState();
}

class _OwnerWhatsAppLogsViewState extends State<OwnerWhatsAppLogsView> {
  String _filter = 'All';

  final List<Map<String, String>> _logs = [
    {
      'name': 'Muhammad Hamza',
      'phone': '0321-4455667',
      'type': 'Digital Handover Pass & QR',
      'time': '10 mins ago',
      'status': 'read',
    },
    {
      'name': 'Usman Tariq',
      'phone': '0300-8877665',
      'type': 'Deposit Settlement Invoice #RH-9821',
      'time': '1 hour ago',
      'status': 'delivered',
    },
    {
      'name': 'Bilal Ahmed',
      'phone': '0333-1122445',
      'type': 'Booking Request Approval Notice',
      'time': '3 hours ago',
      'status': 'read',
    },
    {
      'name': 'Kashif Ali',
      'phone': '0345-9988112',
      'type': 'Overdue Return SMS & WhatsApp Alert',
      'time': '5 hours ago',
      'status': 'failed',
    },
  ];

  List<Map<String, String>> get _filteredLogs {
    if (_filter == 'All') return _logs;
    return _logs
        .where((l) => l['status']?.toLowerCase() == _filter.toLowerCase())
        .toList();
  }

  void _resendAlert(int index) {
  final l10n = AppLocalizations.of(context)!;
    AppFeedback.showSuccess(
        context, l10n.whatsappLogsResent);
    setState(() {
      _logs[index]['status'] = 'delivered';
    });
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredLogs;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.whatsappLogsTitle,
              subtitle: l10n.whatsappLogsSubtitle,
              onBack: widget.onBack,
            ),
            // E3: 48dp chip + 6dp vertical padding each side — the
            // old 48dp row squeezed the filter chips to 36dp.
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Delivered', 'Read', 'Failed'].map((tab) {
                  final isSelected = _filter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      label: Text(_filterLabel(l10n, tab)),
                      selected: isSelected,
                      selectedColor: AppColors.secondary,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface),
                      onSelected: (_) => setState(() => _filter = tab),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return WhatsAppLogTile(
                    recipientName: item['name']!,
                    phone: item['phone']!,
                    messageType: item['type']!,
                    timestamp: item['time']!,
                    status: item['status']!,
                    onResend: () => _resendAlert(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stored log-filter codes mapped to localized labels — the stored
/// value itself is never changed.
String _filterLabel(AppLocalizations l10n, String tab) => {'All': l10n.filterAll, 'Delivered': l10n.whatsappLogsDelivered, 'Read': l10n.whatsappLogsRead, 'Failed': l10n.whatsappLogsFailed}[tab] ?? tab;
