import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_shell.dart';

/// Phase A (A5) — the activity log: every admin action, newest first,
/// with a text filter and a CSV export. The `audit_logs` collection is
/// immutable in Firestore rules (read admin, create authenticated,
/// update/delete never), so nothing here can edit or delete an entry.
class AdminActivityLogView extends StatefulWidget {
  const AdminActivityLogView({super.key});

  @override
  State<AdminActivityLogView> createState() => _AdminActivityLogViewState();
}

class _AdminActivityLogViewState extends State<AdminActivityLogView> {
  final _searchController = TextEditingController();
  List<AuditLogEntry> _entries = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final entries = await sl<AdminRemoteDataSource>().getAuditLogs();
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AuditLogEntry> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    return _entries.where((e) {
      return e.action.toLowerCase().contains(query) ||
          e.actorEmail.toLowerCase().contains(query) ||
          e.targetType.toLowerCase().contains(query) ||
          e.detail.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _exportCsv() async {
    final csv = AdminRemoteDataSource.auditLogsCsv(_visible);
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
      if (mounted) {
        AppFeedback.showError(context, 'Could not share the CSV file.');
      }
    }
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search by action, admin, or target…',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _exportButton() {
    return OutlinedButton.icon(
      onPressed: _visible.isEmpty ? null : _exportCsv,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Export CSV'),
    );
  }

  // Locale-aware: the old hand-rolled English month list ignored the
  // admin's locale (Urdu users saw English month names).
  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM yyyy HH:mm', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminActivity,
      title: 'Activity Log',
      subtitle: 'Every admin action, newest first — immutable',
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            // Compact: search + Export CSV stacked — side by side
            // they leave the search ~160px at 360px and overflow
            // at larger text scales.
            if (compact) ...[
              _searchField(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _exportButton(),
              ),
            ] else
              Row(
                children: [
                  Expanded(child: _searchField()),
                  const SizedBox(width: 12),
                  _exportButton(),
                ],
              ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: 'Could not load the activity log.',
                          onRetry: _load,
                        )
                      : _visible.isEmpty
                          ? const AppEmptyState(
                              title: 'No audit entries yet',
                              message:
                                  'Admin actions will appear here as they happen.',
                            )
                          : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final e = _visible[i];
                            final subtitle =
                                '${e.actorEmail} • ${e.targetType} ${e.targetId}'
                                '${e.detail.isEmpty ? '' : '\n${e.detail}'}'
                                '${e.decision == null ? '' : '\nDecision: ${e.decision}'}';
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              // Compact: the trailing date squeezes the
                              // entry text at 360px (worse at 2.0x
                              // scale), so the date joins the subtitle.
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: const Icon(Icons.history_rounded,
                                      size: 20),
                                ),
                                title: Text(
                                  e.action,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      ),
                                ),
                                subtitle: Text(
                                  compact
                                      ? '$subtitle\n${_formatDate(context, e.createdAt)}'
                                      : subtitle,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                isThreeLine: true,
                                trailing: compact
                                    ? null
                                    : Text(
                                        _formatDate(context, e.createdAt),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                              ),
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
