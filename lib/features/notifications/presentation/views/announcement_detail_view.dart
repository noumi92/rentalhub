import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// Admin final pass (2026-11-10) — the announcement detail screen.
///
/// Worker 1 added `AnnouncementPushHandler` (emits the tapped push's
/// `announcementId` on `announcementOpened`) but nothing subscribed
/// and no screen existed to land on. `main.dart` subscribes and
/// routes here; this view reads `announcements/{id}` (the document
/// the admin panel writes: `title_en` / `title_ur`, `body_en` /
/// `body_ur`, `created_at`) and shows it. A missing document is an
/// honest empty state, a failed read an honest error state — never
/// a placeholder announcement.
///
/// `loader` is an injectable seam for tests (widget tests have no
/// Firestore); production callers leave it null and the view reads
/// Firestore directly. Foreground in-app banners are out of scope
/// (they need `flutter_local_notifications`, deliberately not added).
///
/// F-m16 (admin audit 2026-11-14): opening this screen reports the
/// open — `stats_opened` on `announcements/{id}` is incremented
/// once per open (the default reporter; override with [onOpened] in
/// tests). Delivered is still not tracked: FCM delivery receipts
/// are not reported, and the admin history labels the column
/// honestly instead of estimating it.
class AnnouncementDetailView extends StatefulWidget {
  const AnnouncementDetailView({
    super.key,
    required this.announcementId,
    this.loader,
    this.onOpened,
  });

  final String announcementId;

  /// Reads one announcement document. Returns null when the document
  /// does not exist; throws when the read fails.
  final Future<Map<String, dynamic>?> Function(String id)? loader;

  /// Reports that this announcement was opened. Defaults to a
  /// Firestore `stats_opened` increment; a failure to report never
  /// fails the screen.
  final Future<void> Function(String id)? onOpened;

  @override
  State<AnnouncementDetailView> createState() =>
      _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _failed = false;
  bool _openReported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, dynamic>?> _defaultLoader(String id) async {
    final snap = await FirebaseFirestore.instance
        .collection('announcements')
        .doc(id)
        .get();
    return snap.exists ? snap.data() : null;
  }

  Future<void> _defaultReportOpen(String id) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(id)
        .update({'stats_opened': FieldValue.increment(1)});
  }

  Future<void> _load() async {
    try {
      final data =
          await (widget.loader ?? _defaultLoader)(widget.announcementId);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
      // F-m16: report the open once, only for a real document.
      if (data != null && !_openReported) {
        _openReported = true;
        try {
          await (widget.onOpened ?? _defaultReportOpen)(
              widget.announcementId);
        } catch (_) {
          // Reporting must never fail the screen.
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _isLoading = false;
        });
      }
    }
  }

  DateTime? _dateOf(Map<String, dynamic> data) {
    final created = data['created_at'];
    if (created is Timestamp) return created.toDate();
    if (created is String) return DateTime.tryParse(created);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final title = _data == null
        ? ''
        : _pick(_data!, isUrdu ? 'title_ur' : 'title_en',
            isUrdu ? 'title_en' : 'title_ur');
    final body = _data == null
        ? ''
        : _pick(_data!, isUrdu ? 'body_ur' : 'body_en',
            isUrdu ? 'body_en' : 'body_ur');
    final date = _data == null ? null : _dateOf(_data!);
    return Scaffold(
      appBar: MinimalAppBar(title: l10n.anncTitle),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? AppLoadingState(message: l10n.anncLoading)
            : _failed
                ? AppErrorState(
                    message: l10n.anncLoadError,
                    onRetry: () {
                      setState(() {
                        _isLoading = true;
                        _failed = false;
                      });
                      _load();
                    },
                  )
                : _data == null
                    ? AppEmptyState(title: l10n.anncNotFound)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty ? l10n.anncTitle : title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (date != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                MaterialLocalizations.of(context)
                                    .formatMediumDate(date),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              body,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  static String _pick(
      Map<String, dynamic> data, String preferred, String fallback) {
    final first = (data[preferred] as String? ?? '').trim();
    if (first.isNotEmpty) return first;
    return (data[fallback] as String? ?? '').trim();
  }
}
