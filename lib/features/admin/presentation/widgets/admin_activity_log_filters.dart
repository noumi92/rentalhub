import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_status_chip.dart';

/// The activity log's search + server-side filters + CSV export
/// (F-m3): the text search stays, and the log gains an action-family
/// dropdown, an actor-email field, and a From/To date range, all
/// applied server-side by the data source.
///
/// The action families are prefixes — `support_ticket` matches
/// `support_ticket_closed`, `support_ticket_replied`, … — because
/// several actions carry a dynamic suffix. Labels are the humanised
/// family names, never raw enum values.
class AdminActivityLogFilters extends StatelessWidget {
  const AdminActivityLogFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.actionPrefix,
    required this.onActionChanged,
    required this.actorController,
    required this.onActorChanged,
    required this.from,
    required this.to,
    required this.onDatesChanged,
    required this.onClearFilters,
    required this.exportEntries,
    required this.compact,
  });

  static const actionFamilies = <String>[
    'admin_invite',
    'admin_role',
    'shop_application',
    'car_review',
    'customer',
    'dispute',
    'review_moderation',
    'support_ticket',
    'platform_settings',
    'totp_reset',
    'blacklist_appeal',
    'announcement',
  ];

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? actionPrefix;
  final ValueChanged<String?> onActionChanged;
  final TextEditingController actorController;
  final ValueChanged<String> onActorChanged;
  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onDatesChanged;
  final VoidCallback onClearFilters;

  /// The entries the CSV export shares (the visible, filtered
  /// entries — the export covers what the admin is looking at).
  final List<AuditLogEntry> exportEntries;
  final bool compact;

  bool get _hasServerFilter =>
      actionPrefix != null ||
      actorController.text.trim().isNotEmpty ||
      from != null ||
      to != null;

  Future<void> _exportCsv(BuildContext context) async {
    final csv = AdminRemoteDataSource.auditLogsCsv(exportEntries);
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(csv),
              name: 'rentalhub-audit-log.csv',
              mimeType: 'text/csv',
            ),
          ],
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppFeedback.showError(context,
            AppLocalizations.of(context)!.admin2_activityCsvFailed);
      }
    }
  }

  Future<void> _pickDate(BuildContext context,
      {required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate:
          isFrom ? (from ?? DateTime.now()) : (to ?? DateTime.now()),
    );
    if (picked == null) return;
    onDatesChanged(isFrom ? picked : from, isFrom ? to : picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    Widget dateButton(String label, DateTime? date, VoidCallback onPick) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today_rounded, size: 18),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
        label: Text(
          date == null
              ? '$label…'
              : '$label ${DateFormat.yMd(locale).format(date)}',
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onPick,
      );
    }

    final searchField = TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: l10n?.admin2_activitySearchHint ??
            'Search by action, admin, or target…',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
    final exportButton = OutlinedButton.icon(
      onPressed:
          exportEntries.isEmpty ? null : () => _exportCsv(context),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text(l10n?.admin2_activityExportCsv ?? 'Export CSV'),
    );
    final actionDropdown = DropdownButtonFormField<String>(
      // The field is rebuilt when the selected family changes (for
      // example on Clear filters) so `initialValue` always matches
      // the current filter; `value:` is deprecated on this Flutter.
      key: ValueKey(actionPrefix),
      initialValue: actionPrefix,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n?.adminAuditFilterAction ?? 'Action',
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        DropdownMenuItem(
          value: null,
          child: Text(l10n?.adminAuditAllActions ?? 'All actions'),
        ),
        for (final family in actionFamilies)
          DropdownMenuItem(
            value: family,
            child: Text(humanizeStatus(family, l10n)),
          ),
      ],
      onChanged: onActionChanged,
    );
    final actorField = TextField(
      controller: actorController,
      onChanged: onActorChanged,
      decoration: InputDecoration(
        labelText: l10n?.adminAuditFilterActor ?? 'Admin email',
        hintText: 'admin@rentalhub.pk',
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
    final dateRow = Row(
      children: [
        Expanded(
            child: dateButton(l10n?.adminAuditFilterFrom ?? 'From', from,
                () => _pickDate(context, isFrom: true))),
        const SizedBox(width: 12),
        Expanded(
            child: dateButton(l10n?.adminAuditFilterTo ?? 'To', to,
                () => _pickDate(context, isFrom: false))),
      ],
    );
    final clearButton = TextButton.icon(
      onPressed: _hasServerFilter ? onClearFilters : null,
      icon: const Icon(Icons.filter_list_off_rounded, size: 18),
      label: Text(l10n?.adminAuditClearFilters ?? 'Clear filters'),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          actionDropdown,
          const SizedBox(height: 12),
          actorField,
          const SizedBox(height: 12),
          dateRow,
          const SizedBox(height: 4),
          clearButton,
          const SizedBox(height: 4),
          SizedBox(width: double.infinity, child: exportButton),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 12),
            exportButton,
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: actionDropdown),
            const SizedBox(width: 12),
            Expanded(child: actorField),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: dateRow),
            const SizedBox(width: 12),
            clearButton,
          ],
        ),
      ],
    );
  }
}
