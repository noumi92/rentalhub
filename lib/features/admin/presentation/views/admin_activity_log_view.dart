import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
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
    final entries = await sl<AdminRemoteDataSource>().getAuditLogs();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
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
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: RouteNames.adminActivity,
      title: 'Activity Log',
      subtitle: 'Every admin action, newest first — immutable',
      onRefresh: _load,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by action, admin, or target…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _visible.isEmpty ? null : _exportCsv,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visible.isEmpty
                      ? Center(
                          child: Text(
                            'No audit entries yet — admin actions will appear here as they happen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final e = _visible[i];
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
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
                                  '${e.actorEmail} • ${e.targetType} ${e.targetId}'
                                  '${e.detail.isEmpty ? '' : '\n${e.detail}'}'
                                  '${e.decision == null ? '' : '\nDecision: ${e.decision}'}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  _formatDate(e.createdAt),
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
