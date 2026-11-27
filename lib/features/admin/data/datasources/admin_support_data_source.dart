import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/csv_escape.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../finance/data/models/finance_transfer_model.dart';
import '../../domain/admin_permissions.dart';
import '../../domain/report_series.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_session.dart';
import 'admin_pagination.dart';
import '../../../../l10n/app_localizations.dart';

/// Phase E — support, settings, announcements, and reports.
///
/// E1: the tickets inbox reads `support_tickets` (the customer form
/// writes them). The SLA is real: High 1 h, Medium 4 h, Low 24 h
/// from the ticket's createdAt, using the priority the customer form
/// now records (older tickets without one default to Medium).
/// Replies go to a `replies` subcollection (customer-visible once a
/// customer thread view exists); internal notes go to a separate
/// `internal_notes` subcollection the customer never sees.
///
/// E3: announcements are real Firestore records. Delivery runs
/// through the `sendAnnouncement` Cloud Function (admin-only):
/// push goes out via FCM to the tokens the app registers on sign-in
/// (see PushTokenService); WhatsApp waits for the D2 token and stays
/// `pending_whatsapp` — never marked sent without a delivery.
class AdminSupportDataSource {
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  AdminSupportDataSource({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore,
        _functions = functions;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFunctions? get _resolvedFunctions {
    if (_functions != null) return _functions;
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return null;
    }
  }

  // ---- E1: support tickets ----

  /// Phase 2 (2.4): one ticket for its detail route. F-M6: throws
  /// when the document cannot be read (the detail view shows its
  /// error state); null only when the ticket does not exist, or
  /// with no Firestore (tests).
  Future<SupportTicket?> getTicket(String ticketId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final doc = await firestore
        .collection('support_tickets')
        .doc(ticketId)
        .get();
    final data = doc.data();
    if (data == null) return null;
    return SupportTicket.fromMap(doc.id, data);
  }

  Future<List<SupportTicket>> getTickets({String status = 'all'}) async {
    final page = await getTicketsPage(status: status, limit: 100);
    return page.items;
  }

  /// Phase 4 (4.3) — client-side sort over loaded tickets (the
  /// no-Firestore path and the view's search results). Priority is
  /// deliberately NOT a server sort: it is a string field
  /// ('high'/'medium'/'low') with no severity order in Firestore,
  /// so an alphabetical sort would mislead.
  static List<SupportTicket> sortTickets(
      List<SupportTicket> tickets, String sort) {
    final list = List<SupportTicket>.of(tickets);
    DateTime at(SupportTicket t) =>
        t.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (sort) {
      case 'dateOldest':
        list.sort((a, b) => at(a).compareTo(at(b)));
      case 'statusAsc':
        list.sort((a, b) {
          final c = a.status.compareTo(b.status);
          return c != 0 ? c : at(b).compareTo(at(a));
        });
      default:
        list.sort((a, b) => at(b).compareTo(at(a)));
    }
    return list;
  }

  /// Phase 4 (4.3) — client-side sort over loaded announcements
  /// (the no-Firestore path).
  static List<AdminAnnouncement> sortAnnouncements(
      List<AdminAnnouncement> announcements, String sort) {
    final list = List<AdminAnnouncement>.of(announcements);
    DateTime at(AdminAnnouncement a) =>
        a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    switch (sort) {
      case 'dateOldest':
        list.sort((a, b) => at(a).compareTo(at(b)));
      case 'titleAsc':
        list.sort((a, b) => a.titleEn.compareTo(b.titleEn));
      case 'statusAsc':
        list.sort((a, b) {
          final c = a.status.compareTo(b.status);
          return c != 0 ? c : at(b).compareTo(at(a));
        });
      default:
        list.sort((a, b) => at(b).compareTo(at(a)));
    }
    return list;
  }

  /// Phase 4 (4.4c) — how many tickets the current filter matches
  /// in total, so the inbox can say "Showing first N of M".
  Future<int> countTickets({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return (await getTickets(status: status)).length;
    final count = await (status == 'all'
            ? firestore.collection('support_tickets').count()
            : firestore
                .collection('support_tickets')
                .where('status', isEqualTo: status)
                .count())
        .get();
    return count.count ?? 0;
  }

  /// One page of the tickets inbox, newest first. Phase 3 (3.4):
  /// the old status-filtered branch capped filtered pages at 100
  /// with `hasMore: false` and no cursor — a filtered inbox simply
  /// stopped. Both branches now run the same query shape
  /// (`status` + `createdAt`, composite index in
  /// firestore.indexes.json) with limit+1 and a cursor, so
  /// filtered pages paginate like the unfiltered inbox.
  ///
  /// F-M6: a failed read throws — the tickets view shows its error
  /// state instead of "No tickets" during an outage. An empty page
  /// is returned only with no Firestore (tests).
  Future<AdminPage<SupportTicket>> getTicketsPage({
    String status = 'all',
    int limit = 50,
    Object? cursor,
    String sort = 'dateNewest',
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) {
      return const AdminPage(items: [], hasMore: false);
    }
    // Phase 4 (4.3) — the sort is server-side: date orders by
    // `createdAt`, status by `status` then newest first (the
    // status+createdAt DESC index already exists in
    // firestore.indexes.json; the ASC variant is added there).
    Query<Map<String, dynamic>> base(String field, bool descending) {
      Query<Map<String, dynamic>> q =
          firestore.collection('support_tickets');
      if (status != 'all') {
        q = q.where('status', isEqualTo: status);
      }
      return q.orderBy(field, descending: descending);
    }

    var query = switch (sort) {
      'dateOldest' => base('createdAt', false),
      'statusAsc' =>
        base('status', false).orderBy('createdAt', descending: true),
      _ => base('createdAt', true),
    };
    var paged = query.limit(limit + 1);
    final lastDoc = cursor is DocumentSnapshot ? cursor : null;
    if (lastDoc != null) paged = paged.startAfterDocument(lastDoc);
    final snap = await paged.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPage(
      items: pageDocs
          .map((d) => SupportTicket.fromMap(d.id, d.data()))
          .toList(),
      hasMore: hasMore,
      cursor: hasMore ? pageDocs.last : null,
    );
  }

  /// Server-side ticket search: it covers the whole inbox, not just
  /// the loaded page. A customer-ID match is a direct query; anything
  /// else scans the inbox in bounded pages (at most 500 tickets)
  /// for a message/customer match, newest first.
  Future<List<SupportTicket>> searchTickets(
    String query, {
    String status = 'all',
    int limit = 50,
  }) async {
    final firestore = _resolvedFirestore;
    final q = query.trim();
    if (firestore == null || q.isEmpty) return [];
    try {
      final byCustomer = await firestore
          .collection('support_tickets')
          .where('customerId', isEqualTo: q)
          .limit(limit)
          .get();
      final found = byCustomer.docs
          .map((d) => SupportTicket.fromMap(d.id, d.data()))
          .where((t) => status == 'all' || t.status == status)
          .toList();
      if (found.isNotEmpty) return found.take(limit).toList();
      final needle = q.toLowerCase();
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      var scanned = 0;
      while (scanned < 500 && found.length < limit) {
        var pageQuery = firestore
            .collection('support_tickets')
            .orderBy('createdAt', descending: true)
            .limit(100);
        if (cursor != null) {
          pageQuery = pageQuery.startAfterDocument(cursor);
        }
        final snap = await pageQuery.get();
        if (snap.docs.isEmpty) break;
        scanned += snap.docs.length;
        cursor = snap.docs.last;
        for (final d in snap.docs) {
          final t = SupportTicket.fromMap(d.id, d.data());
          if (status != 'all' && t.status != status) continue;
          if (t.message.toLowerCase().contains(needle) ||
              t.customerId.toLowerCase().contains(needle)) {
            found.add(t);
            if (found.length >= limit) break;
          }
        }
        if (snap.docs.length < 100) break;
      }
      return found;
    } catch (_) {
      return [];
    }
  }

  /// F-M6: a failed read throws — the ticket sheet shows its error
  /// state with a retry instead of "No replies yet" during an
  /// outage. `[]` is returned only with no Firestore (tests).
  Future<List<TicketMessage>> getTicketReplies(String ticketId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('replies')
        .orderBy('created_at')
        .get();
    return snap.docs
        .map((d) => TicketMessage.fromMap(d.id, d.data()))
        .toList();
  }

  /// F-M6: a failed read throws (see [getTicketReplies]).
  Future<List<TicketMessage>> getTicketNotes(String ticketId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('internal_notes')
        .orderBy('created_at')
        .get();
    return snap.docs
        .map((d) => TicketMessage.fromMap(d.id, d.data()))
        .toList();
  }

  /// F-C1: replying is triage, so every admin role holds it
  /// ([AdminPermission.triageTicket]). The caller's role is passed
  /// by the sheet when it already resolved it, otherwise resolved
  /// from the session here; an unresolvable role refuses the write
  /// (fail closed).
  Future<bool> replyToTicket({
    required String ticketId,
    required String text,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.triageTicket,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('replies')
          .add({
        'author_role': 'admin',
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
      });
      await firestore.collection('support_tickets').doc(ticketId).update({
        'status': 'in_progress',
      });
      // F-M18 (ticket part): a reply is the substantive act of
      // support — it leaves an audit trace so the activity log can
      // answer who told the customer what, and when.
      await AdminAuditService.logAction(
        action: 'support_ticket_replied',
        targetType: 'support_ticket',
        targetId: ticketId,
        detail: 'Admin replied to the ticket.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// F-C1: an internal note is triage ([AdminPermission.
  /// triageTicket]) — see [replyToTicket].
  Future<bool> addTicketNote({
    required String ticketId,
    required String text,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.triageTicket,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('internal_notes')
          .add({
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
      });
      // F-M18 (ticket part): internal notes are logged too — the
      // note's text stays in the ticket, only the fact is audited.
      await AdminAuditService.logAction(
        action: 'support_ticket_noted',
        targetType: 'support_ticket',
        targetId: ticketId,
        detail: 'Admin added an internal note to the ticket.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// F-C1: moving a ticket to `closed` needs [AdminPermission.
  /// resolveTicket] (super admin + operations only); any other
  /// status move (in_progress, escalated) is triage
  /// ([AdminPermission.triageTicket]) — see [replyToTicket].
  Future<bool> setTicketStatus({
    required String ticketId,
    required String status,
    String? adminRole,
  }) async {
    final permission = status == 'closed'
        ? AdminPermission.resolveTicket
        : AdminPermission.triageTicket;
    if (!await AdminSession.currentAdminCan(permission,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore.collection('support_tickets').doc(ticketId).update({
        'status': status,
      });
      await AdminAuditService.logAction(
        action: 'support_ticket_$status',
        targetType: 'support_ticket',
        targetId: ticketId,
        detail: 'Ticket moved to $status.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- E2: platform settings ----

  /// F-M12: the read result is three-way — a [PlatformSettings]
  /// when the document exists, null when no settings document has
  /// ever been saved, and a throw when the read itself fails. The
  /// old version returned factory defaults in all three cases, so
  /// a load failure populated the editable form with defaults and
  /// one Save overwrote the platform's real settings. With no
  /// Firestore (unit tests / Firebase not initialised) the factory
  /// defaults are returned, so the offline tests keep their
  /// expectations.
  Future<PlatformSettings?> getPlatformSettings() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return const PlatformSettings();
    final doc = await firestore
        .collection('platform_settings')
        .doc('global')
        .get();
    final data = doc.data();
    if (data == null) return null;
    return PlatformSettings.fromMap(data);
  }

  /// F-C1: super admin + operations only ([AdminPermission.
  /// managePlatform]) — see [replyToTicket].
  Future<bool> savePlatformSettings(PlatformSettings settings,
      {String? adminRole}) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.managePlatform,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      await firestore
          .collection('platform_settings')
          .doc('global')
          .set(settings.toMap(), SetOptions(merge: true));
      await AdminAuditService.logAction(
        action: 'platform_settings_updated',
        targetType: 'platform_settings',
        targetId: 'global',
        detail: 'Platform settings saved.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- E3: announcements ----

  /// F-M6: a failed read throws — the announcements view shows its
  /// error state instead of an empty history during an outage. `[]`
  /// is returned only with no Firestore (tests).
  Future<List<AdminAnnouncement>> getAnnouncements() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    final snap = await firestore
        .collection('announcements')
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => AdminAnnouncement.fromMap(d.id, d.data()))
        .toList();
  }

  /// Phase 3 (3.2/3.4) — one page of announcements, newest first,
  /// with the same cursor pagination as the tickets inbox, so the
  /// history no longer stops at a silent 50-row cap.
  Future<AdminPage<AdminAnnouncement>> getAnnouncementsPage({
    int limit = 20,
    Object? cursor,
    String sort = 'dateNewest',
  }) async {
    final firestore = _resolvedFirestore;
    final total = await countAnnouncements();
    if (firestore == null) {
      return AdminPage(items: [], hasMore: false, total: total);
    }
    // Phase 4 (4.3) — the sort is server-side: date orders by
    // `created_at`, title by `title_en`, status by `status` then
    // newest first (the status+created_at DESC index is added to
    // firestore.indexes.json).
    var query = switch (sort) {
      'dateOldest' => firestore
          .collection('announcements')
          .orderBy('created_at'),
      'titleAsc' => firestore
          .collection('announcements')
          .orderBy('title_en'),
      'statusAsc' => firestore
          .collection('announcements')
          .orderBy('status')
          .orderBy('created_at', descending: true),
      _ => firestore
          .collection('announcements')
          .orderBy('created_at', descending: true),
    };
    query = query.limit(limit + 1);
    final lastDoc = cursor is DocumentSnapshot ? cursor : null;
    if (lastDoc != null) query = query.startAfterDocument(lastDoc);
    final snap = await query.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;
    return AdminPage(
      items: pageDocs
          .map((d) => AdminAnnouncement.fromMap(d.id, d.data()))
          .toList(),
      hasMore: hasMore,
      cursor: hasMore ? pageDocs.last : null,
      total: total,
    );
  }

  /// Phase 3 (3.4) — how many announcements exist in total, so the
  /// history can say "Showing first N of M".
  Future<int> countAnnouncements() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return (await getAnnouncements()).length;
    final count =
        await firestore.collection('announcements').count().get();
    return count.count ?? 0;
  }

  /// Phase 3 (3.2) — one announcement for its detail route. F-M6:
  /// throws when the document cannot be read; null only when it
  /// does not exist, or with no Firestore (tests).
  Future<AdminAnnouncement?> getAnnouncement(String announcementId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    final doc = await firestore
        .collection('announcements')
        .doc(announcementId)
        .get();
    final data = doc.data();
    if (data == null) return null;
    return AdminAnnouncement.fromMap(doc.id, data);
  }

  /// Phase 3 (3.2) — edit a draft or scheduled announcement. Only
  /// unsent items may change: a `sent` or `pending_whatsapp`
  /// announcement is read-only history (its push already went out,
  /// and sendAnnouncement refuses a re-send server-side). Returns
  /// false when the caller may not edit, the announcement does not
  /// exist, or it is already sent. Editing a scheduled item keeps
  /// its status; editing a draft keeps it a draft unless a schedule
  /// is added, which moves it to `scheduled`.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// managePlatform]) — see [createAnnouncement].
  Future<bool> updateAnnouncement({
    required String announcementId,
    required String titleEn,
    required String titleUr,
    required String bodyEn,
    required String bodyUr,
    required String audienceRole,
    required String audienceCity,
    required String audiencePlan,
    required String channel,
    DateTime? scheduledAt,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.managePlatform,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final doc = await firestore
          .collection('announcements')
          .doc(announcementId)
          .get();
      final data = doc.data();
      if (data == null) return false;
      final status = data['status'] as String? ?? 'draft';
      if (status == 'sent' || status == 'pending_whatsapp') {
        return false;
      }
      await firestore.collection('announcements').doc(announcementId).update({
        'title_en': titleEn,
        'title_ur': titleUr,
        'body_en': bodyEn,
        'body_ur': bodyUr,
        'audience_role': audienceRole,
        'audience_city': audienceCity,
        'audience_plan': audiencePlan,
        'channel': channel,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'status': scheduledAt == null ? 'draft' : 'scheduled',
      });
      await AdminAuditService.logAction(
        action: 'announcement_updated',
        targetType: 'announcement',
        targetId: announcementId,
        detail: '$titleEn — $audienceRole/$audienceCity/$audiencePlan, '
            '$channel${scheduledAt == null ? ', draft' : ', scheduled'}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Phase 3 (3.2) — delete a draft or scheduled announcement.
  /// Sent (and `pending_whatsapp`) announcements are read-only
  /// history and cannot be deleted. Returns false when the caller
  /// may not delete, the announcement does not exist, or it is
  /// already sent.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// managePlatform]) — see [createAnnouncement].
  Future<bool> deleteAnnouncement(
    String announcementId, {
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.managePlatform,
        adminRole: adminRole)) {
      return false;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return false;
    try {
      final doc = await firestore
          .collection('announcements')
          .doc(announcementId)
          .get();
      final data = doc.data();
      if (data == null) return false;
      final status = data['status'] as String? ?? 'draft';
      if (status == 'sent' || status == 'pending_whatsapp') {
        return false;
      }
      await firestore
          .collection('announcements')
          .doc(announcementId)
          .delete();
      await AdminAuditService.logAction(
        action: 'announcement_deleted',
        targetType: 'announcement',
        targetId: announcementId,
        detail: (data['title_en'] as String?) ?? announcementId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// F-C1: super admin + operations only ([AdminPermission.
  /// managePlatform]) — see [replyToTicket]. Returns null when the
  /// caller may not create announcements.
  Future<String?> createAnnouncement({
    required String titleEn,
    required String titleUr,
    required String bodyEn,
    required String bodyUr,
    required String audienceRole,
    required String audienceCity,
    required String audiencePlan,
    required String channel,
    DateTime? scheduledAt,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.managePlatform,
        adminRole: adminRole)) {
      return null;
    }
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final doc = await firestore.collection('announcements').add({
        'title_en': titleEn,
        'title_ur': titleUr,
        'body_en': bodyEn,
        'body_ur': bodyUr,
        'audience_role': audienceRole,
        'audience_city': audienceCity,
        'audience_plan': audiencePlan,
        'channel': channel,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'status': scheduledAt == null ? 'draft' : 'scheduled',
        'stats_sent': 0,
        'stats_delivered': 0,
        'stats_opened': 0,
        'created_at': FieldValue.serverTimestamp(),
      });
      // F-M18 (admin audit 2026-11-14): announcement creation is an
      // admin action (plan A5) — it was the one E3 write with no
      // audit-log entry, so the activity log could not answer "who
      // drafted this, and when?" (Sending is logged server-side by
      // sendAnnouncement as `announcement_sent`.)
      await AdminAuditService.logAction(
        action: 'announcement_created',
        targetType: 'announcement',
        targetId: doc.id,
        detail: '$titleEn — $audienceRole/$audienceCity/$audiencePlan, '
            '$channel${scheduledAt == null ? ', draft' : ', scheduled'}',
      );
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  /// Sends an announcement through the `sendAnnouncement` Cloud
  /// Function. `test: true` delivers only to the calling admin's own
  /// device. Returns the Function's result map, or null when the
  /// call could not be made.
  ///
  /// F-C1: super admin + operations only ([AdminPermission.
  /// managePlatform]) — see [replyToTicket]. Returns null when the
  /// caller may not send announcements.
  Future<Map<String, dynamic>?> sendAnnouncement({
    required String announcementId,
    bool test = false,
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(AdminPermission.managePlatform,
        adminRole: adminRole)) {
      return null;
    }
    final functions = _resolvedFunctions;
    if (functions == null) return null;
    try {
      final result = await functions
          .httpsCallable('sendAnnouncement')
          .call({'announcementId': announcementId, 'test': test});
      final data = result.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'ok': true};
    } catch (_) {
      return null;
    }
  }

  /// The end of the picked To day (23:59:59.999): a report for a
  /// range ending "today" must include today's bookings, not drop
  /// the whole day because the picked date sits at midnight.
  static DateTime inclusiveTo(DateTime to) =>
      DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

  static DateTime _startOfDay(DateTime from) =>
      DateTime(from.year, from.month, from.day);

  // ---- E4: reports ----

  Future<AdminReport?> getReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    // F-M17: the range is inclusive on both ends, and the range is
    // pushed into the queries instead of loading whole collections
    // and filtering client-side. The date fields are ISO strings in
    // the writers (BookingModel / FinanceTransferModel /
    // CustomerModel / fileDispute), so string bounds compare in
    // chronological order; the client-side checks below stay as a
    // backstop for any document whose field parses differently.
    final rangeFrom = _startOfDay(from);
    final rangeTo = inclusiveTo(to);
    final fromIso = rangeFrom.toIso8601String();
    final toIso = rangeTo.toIso8601String();
    try {
      final bookingsSnap = await firestore
          .collection('bookings')
          .where('pickupTime', isGreaterThanOrEqualTo: fromIso)
          .where('pickupTime', isLessThanOrEqualTo: toIso)
          .limit(1000)
          .get();
      final bookings = bookingsSnap.docs
          .map((d) => BookingModel.fromMap(d.data(), d.id))
          .where((b) =>
              !b.pickupTime.isBefore(rangeFrom) &&
              !b.pickupTime.isAfter(rangeTo))
          .toList();
      // Phase 4 (4.2): the 1,000-row cap is stated, not silent —
      // a full page may mean more rows exist past the cap. The
      // flags are computed at the return, once both snapshots
      // exist.

      final shopsSnap = await firestore.collection('shops').limit(200).get();
      final shopCity = <String, String>{};
      for (final d in shopsSnap.docs) {
        shopCity[d.id] = (d.data()['city'] as String?) ?? 'Unknown';
      }

      final bookingsByCity = <String, int>{};
      final bookingsByShop = <String, int>{};
      var revenue = 0;
      for (final b in bookings) {
        final city = shopCity[b.shopId] ?? 'Unknown';
        bookingsByCity[city] = (bookingsByCity[city] ?? 0) + 1;
        bookingsByShop[b.shopName ?? b.shopId] =
            (bookingsByShop[b.shopName ?? b.shopId] ?? 0) + 1;
        if (b.status == 'completed' || b.status == 'active' || b.status == 'paid') {
          revenue += b.totalAmount;
        }
      }

      final transfersSnap = await firestore
          .collection('finance_transfers')
          .where('createdAt', isGreaterThanOrEqualTo: fromIso)
          .where('createdAt', isLessThanOrEqualTo: toIso)
          .limit(1000)
          .get();
      var income = 0;
      var expense = 0;
      final incomeByCategory = <String, int>{};
      final expenseByCategory = <String, int>{};
      final transfers = <FinanceTransferModel>[];
      for (final d in transfersSnap.docs) {
        final t = FinanceTransferModel.fromMap(d.data());
        if (t.createdAt.isBefore(rangeFrom) || t.createdAt.isAfter(rangeTo)) {
          continue;
        }
        transfers.add(t);
        if (t.kind == 'income') {
          income += t.amountPkr;
          incomeByCategory[t.category] =
              (incomeByCategory[t.category] ?? 0) + t.amountPkr;
        } else {
          expense += t.amountPkr;
          expenseByCategory[t.category] =
              (expenseByCategory[t.category] ?? 0) + t.amountPkr;
        }
      }

      final customersSnap = await firestore
          .collection('customers')
          .where('createdAt', isGreaterThanOrEqualTo: fromIso)
          .where('createdAt', isLessThanOrEqualTo: toIso)
          .limit(1000)
          .get();
      var newCustomers = 0;
      for (final d in customersSnap.docs) {
        final created = d.data()['createdAt'];
        DateTime? createdAt;
        if (created is Timestamp) {
          createdAt = created.toDate();
        } else if (created is String) {
          createdAt = DateTime.tryParse(created);
        }
        if (createdAt != null &&
            !createdAt.isBefore(rangeFrom) &&
            !createdAt.isAfter(rangeTo)) {
          newCustomers++;
        }
      }

      final disputesSnap = await firestore
          .collection('disputes')
          .where('createdAt', isGreaterThanOrEqualTo: fromIso)
          .where('createdAt', isLessThanOrEqualTo: toIso)
          .limit(1000)
          .get();
      var disputesOpen = 0;
      var disputesResolved = 0;
      for (final d in disputesSnap.docs) {
        final data = d.data();
        final created = data['createdAt'];
        DateTime? createdAt;
        if (created is Timestamp) {
          createdAt = created.toDate();
        } else if (created is String) {
          createdAt = DateTime.tryParse(created);
        }
        if (createdAt == null ||
            createdAt.isBefore(rangeFrom) ||
            createdAt.isAfter(rangeTo)) {
          continue;
        }
        if (data['status'] == 'resolved') {
          disputesResolved++;
        } else {
          disputesOpen++;
        }
      }

      final topShops = bookingsByShop.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return AdminReport(
        from: rangeFrom,
        to: rangeTo,
        series: buildReportSeries(
          from: rangeFrom,
          to: rangeTo,
          bookings: bookings,
          transfers: transfers,
        ),
        bookingsTruncated: bookingsSnap.docs.length >= 1000,
        transfersTruncated: transfersSnap.docs.length >= 1000,
        totalBookings: bookings.length,
        completedBookings: bookings.where((b) => b.status == 'completed').length,
        bookingRevenue: revenue,
        bookingsByCity: bookingsByCity,
        topShops: topShops.take(10).toList(),
        financeIncome: income,
        financeExpense: expense,
        incomeByCategory: incomeByCategory,
        expenseByCategory: expenseByCategory,
        newCustomers: newCustomers,
        disputesOpen: disputesOpen,
        disputesResolved: disputesResolved,
      );
    } catch (_) {
      // F-M6: a failed report read throws — the reports view shows
      // its error state instead of "No data for this range". Null
      // is returned only with no Firestore (see the guard above).
      rethrow;
    }
  }

  static String reportCsv(AdminReport report) {
    final rows = <List<String>>[
      [
        'RentalHub platform report',
        report.from.toIso8601String(),
        report.to.toIso8601String(),
      ],
      ['Total bookings', '${report.totalBookings}'],
      ['Completed bookings', '${report.completedBookings}'],
      ['Booking revenue (Rs.)', '${report.bookingRevenue}'],
      ['Finance income (Rs.)', '${report.financeIncome}'],
      ['Finance expense (Rs.)', '${report.financeExpense}'],
      ['New customers', '${report.newCustomers}'],
      ['Disputes open', '${report.disputesOpen}'],
      ['Disputes resolved', '${report.disputesResolved}'],
      [],
      ['Bookings by city'],
      ...report.bookingsByCity.entries.map((e) => [e.key, '${e.value}']),
      [],
      ['Top shops'],
      ...report.topShops.map((e) => [e.key, '${e.value}']),
    ];
    // F-m10: every cell is escaped (a comma in a shop or city name
    // used to break the columns); the header row keeps the old
    // three-column shape.
    return rows.map(csvRow).join('\n');
  }

  /// The PDF summary plan E4 requires (F-m12). One A4 page per
  /// section at most, plain text only — the `pdf` package's built-in
  /// font has no Urdu glyphs, so the summary is English, like the
  /// agreement PDF's Latin-only text. The monthly email stays gated
  /// on D8; this is the on-demand export only.
  static Future<Uint8List> reportPdf(AdminReport report) async {
    final doc = pw.Document();
    final heading =
        pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final body = pw.TextStyle(fontSize: 11, color: PdfColors.black);
    pw.Widget section(String title, List<String> lines) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 14),
          pw.Text(title, style: heading),
          pw.SizedBox(height: 4),
          for (final line in lines) pw.Text(line, style: body),
        ],
      );
    }

    String money(int value) => 'Rs $value';
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text('RentalHub platform report',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            'From ${report.from.toIso8601String().substring(0, 10)}'
            ' to ${report.to.toIso8601String().substring(0, 10)}',
            style: body,
          ),
          section('Key figures', [
            'Total bookings: ${report.totalBookings}',
            'Completed bookings: ${report.completedBookings}',
            'Booking revenue: ${money(report.bookingRevenue)}',
            'Finance income: ${money(report.financeIncome)}',
            'Finance expense: ${money(report.financeExpense)}',
            'New customers: ${report.newCustomers}',
            'Disputes open: ${report.disputesOpen}',
            'Disputes resolved: ${report.disputesResolved}',
          ]),
          section(
            'Bookings by city',
            report.bookingsByCity.isEmpty
                ? ['None in this range.']
                : report.bookingsByCity.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .toList(),
          ),
          section(
            'Top shops',
            report.topShops.isEmpty
                ? ['None in this range.']
                : report.topShops
                    .map((e) => '${e.key}: ${e.value} bookings')
                    .toList(),
          ),
          section(
            'Income by category',
            report.incomeByCategory.isEmpty
                ? ['None in this range.']
                : report.incomeByCategory.entries
                    .map((e) => '${e.key}: ${money(e.value)}')
                    .toList(),
          ),
          section(
            'Expense by category',
            report.expenseByCategory.isEmpty
                ? ['None in this range.']
                : report.expenseByCategory.entries
                    .map((e) => '${e.key}: ${money(e.value)}')
                    .toList(),
          ),
        ],
      ),
    );
    return doc.save();
  }
}

/// One support ticket (E1). Priority comes from the customer form
/// (High/Medium/Low); tickets filed before the form had a priority
/// default to Medium, so the SLA is never invented.
///
/// F-M19: `shopId` / `bookingId` link the ticket to the shop or
/// purchase it is about, where the filing context supplied one
/// (the customer form accepts both; older tickets have neither,
/// and the sheet says so instead of guessing a link).
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.customerId,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.shopId,
    this.bookingId,
  });

  final String id;
  final String customerId;
  final String message;
  final String status;
  final String priority;
  final DateTime? createdAt;
  final String? shopId;
  final String? bookingId;

  int get slaHours =>
      switch (priority.toLowerCase()) { 'high' => 1, 'low' => 24, _ => 4 };

  String slaText() {
    if (createdAt == null) return 'SLA: filed date unknown';
    final left =
        createdAt!.add(Duration(hours: slaHours)).difference(DateTime.now());
    // F-m15: hour-coarse text lied below one hour ("0h of 1h SLA
    // left", "breached by 0h"). Minutes are shown whenever under an
    // hour is left or the breach is under an hour.
    if (left.isNegative) {
      final breached = -left.inMinutes;
      if (breached < 60) return 'SLA breached by ${breached}m';
      final hours = breached ~/ 60;
      final minutes = breached % 60;
      return minutes == 0
          ? 'SLA breached by ${hours}h'
          : 'SLA breached by ${hours}h ${minutes}m';
    }
    if (left.inMinutes < 60) {
      return '${left.inMinutes}m of ${slaHours}h SLA left';
    }
    return '${left.inHours}h of ${slaHours}h SLA left';
  }

  /// Localised form of [slaText] for admin UI, mirroring its
  /// minute-precise branches; `slaText` stays for code-only uses
  /// and tests that assert the English form.
  String slaTextL10n(AppLocalizations l10n) {
    if (createdAt == null) return l10n.admin2_slaUnknownDate;
    final left =
        createdAt!.add(Duration(hours: slaHours)).difference(DateTime.now());
    if (left.isNegative) {
      final breached = -left.inMinutes;
      if (breached < 60) {
        return l10n.admin2_slaBreachedMinutes(breached);
      }
      final hours = breached ~/ 60;
      final minutes = breached % 60;
      return minutes == 0
          ? l10n.admin2_slaBreached(hours)
          : l10n.admin2_slaBreachedHoursMinutes(hours, minutes);
    }
    if (left.inMinutes < 60) {
      return l10n.admin2_slaLeftMinutes(left.inMinutes, slaHours);
    }
    return l10n.admin2_slaLeft(left.inHours, slaHours);
  }

  factory SupportTicket.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    String? linked(String camel, String snake) {
      final value = data[camel] as String? ?? data[snake] as String?;
      return value == null || value.isEmpty ? null : value;
    }

    return SupportTicket(
      id: id,
      customerId: data['customerId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      priority: data['priority'] as String? ?? 'medium',
      createdAt: createdAt,
      shopId: linked('shopId', 'shop_id'),
      bookingId: linked('bookingId', 'booking_id'),
    );
  }
}

/// One reply (customer-visible) or internal note on a ticket.
class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.text,
    required this.authorRole,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String authorRole;
  final DateTime? createdAt;

  factory TicketMessage.fromMap(String id, Map<String, dynamic> data) {
    final created = data['created_at'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return TicketMessage(
      id: id,
      text: data['text'] as String? ?? '',
      authorRole: data['author_role'] as String? ?? 'admin',
      createdAt: createdAt,
    );
  }
}

/// The platform settings (E2): one document, `platform_settings/global`.
class PlatformSettings {
  const PlatformSettings({
    this.liveCities = const ['Lahore', 'Karachi', 'Islamabad'],
    this.carCategories = const ['Sedan', 'SUV', 'Hatchback', 'Luxury'],
    this.advancePercent = 30,
    this.defaultDepositPkr = 10000,
    this.lateGraceMinutes = 60,
    this.supportHours = '9am – 9pm',
    this.defaultAgreementTerms = '',
    this.maintenanceMode = false,
    // Customer rework (Worker E): both default ON. A document or
    // field that does not exist yet is read as ON everywhere.
    this.displayUnverifiedShops = true,
    this.allowBookingsFromUnverifiedShops = true,
  });

  final List<String> liveCities;
  final List<String> carCategories;
  final int advancePercent;
  final int defaultDepositPkr;
  final int lateGraceMinutes;
  final String supportHours;
  final String defaultAgreementTerms;
  final bool maintenanceMode;
  final bool displayUnverifiedShops;
  final bool allowBookingsFromUnverifiedShops;

  factory PlatformSettings.fromMap(Map<String, dynamic> data) {
    return PlatformSettings(
      liveCities:
          List<String>.from(data['live_cities'] as List? ?? const ['Lahore', 'Karachi', 'Islamabad']),
      carCategories: List<String>.from(
          data['car_categories'] as List? ?? const ['Sedan', 'SUV', 'Hatchback', 'Luxury']),
      advancePercent: (data['advance_percent'] as num?)?.toInt() ?? 30,
      defaultDepositPkr: (data['default_deposit_pkr'] as num?)?.toInt() ?? 10000,
      lateGraceMinutes: (data['late_grace_minutes'] as num?)?.toInt() ?? 60,
      supportHours: data['support_hours'] as String? ?? '9am – 9pm',
      defaultAgreementTerms:
          data['default_agreement_terms'] as String? ?? '',
      maintenanceMode: data['maintenance_mode'] as bool? ?? false,
      displayUnverifiedShops:
          data['displayUnverifiedShops'] as bool? ?? true,
      allowBookingsFromUnverifiedShops:
          data['allowBookingsFromUnverifiedShops'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'live_cities': liveCities,
      'car_categories': carCategories,
      'advance_percent': advancePercent,
      'default_deposit_pkr': defaultDepositPkr,
      'late_grace_minutes': lateGraceMinutes,
      'support_hours': supportHours,
      'default_agreement_terms': defaultAgreementTerms,
      'maintenance_mode': maintenanceMode,
      'displayUnverifiedShops': displayUnverifiedShops,
      'allowBookingsFromUnverifiedShops':
          allowBookingsFromUnverifiedShops,
    };
  }

  /// Value equality, so the settings dirty guard can compare the
  /// draft against the last loaded settings (AD-M12).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlatformSettings &&
        other.liveCities.join(',') == liveCities.join(',') &&
        other.carCategories.join(',') == carCategories.join(',') &&
        other.advancePercent == advancePercent &&
        other.defaultDepositPkr == defaultDepositPkr &&
        other.lateGraceMinutes == lateGraceMinutes &&
        other.supportHours == supportHours &&
        other.defaultAgreementTerms == defaultAgreementTerms &&
        other.maintenanceMode == maintenanceMode &&
        other.displayUnverifiedShops == displayUnverifiedShops &&
        other.allowBookingsFromUnverifiedShops ==
            allowBookingsFromUnverifiedShops;
  }

  @override
  int get hashCode => Object.hash(
        liveCities.join(','),
        carCategories.join(','),
        advancePercent,
        defaultDepositPkr,
        lateGraceMinutes,
        supportHours,
        defaultAgreementTerms,
        maintenanceMode,
        displayUnverifiedShops,
        allowBookingsFromUnverifiedShops,
      );
}

/// One announcement (E3). Stats: `sent` is real (the Function's
/// delivery count); `opened` is real too — the announcement detail
/// screen increments it once per open (F-m16). `delivered` stays 0:
/// FCM delivery receipts are not reported, and it is never
/// estimated — the admin history labels it "not tracked yet".
class AdminAnnouncement {
  const AdminAnnouncement({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.bodyEn,
    required this.bodyUr,
    required this.audienceRole,
    required this.audienceCity,
    required this.audiencePlan,
    required this.channel,
    required this.status,
    required this.scheduledAt,
    required this.sent,
    required this.delivered,
    required this.opened,
  });

  final String id;
  final String titleEn;
  final String titleUr;
  final String bodyEn;
  final String bodyUr;
  final String audienceRole;
  final String audienceCity;
  final String audiencePlan;
  final String channel;
  final String status;
  final DateTime? scheduledAt;
  final int sent;
  final int delivered;
  final int opened;

  factory AdminAnnouncement.fromMap(String id, Map<String, dynamic> data) {
    final scheduled = data['scheduled_at'];
    DateTime? scheduledAt;
    if (scheduled is String) scheduledAt = DateTime.tryParse(scheduled);
    return AdminAnnouncement(
      id: id,
      titleEn: data['title_en'] as String? ?? '',
      titleUr: data['title_ur'] as String? ?? '',
      bodyEn: data['body_en'] as String? ?? '',
      bodyUr: data['body_ur'] as String? ?? '',
      audienceRole: data['audience_role'] as String? ?? 'all',
      audienceCity: data['audience_city'] as String? ?? 'all',
      audiencePlan: data['audience_plan'] as String? ?? 'all',
      channel: data['channel'] as String? ?? 'push',
      status: data['status'] as String? ?? 'draft',
      scheduledAt: scheduledAt,
      sent: (data['stats_sent'] as num?)?.toInt() ?? 0,
      delivered: (data['stats_delivered'] as num?)?.toInt() ?? 0,
      opened: (data['stats_opened'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One report (E4): KPIs for a date range, computed live.
class AdminReport {
  const AdminReport({
    required this.from,
    required this.to,
    this.series = const [],
    this.bookingsTruncated = false,
    this.transfersTruncated = false,
    required this.totalBookings,
    required this.completedBookings,
    required this.bookingRevenue,
    required this.bookingsByCity,
    required this.topShops,
    required this.financeIncome,
    required this.financeExpense,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.newCustomers,
    required this.disputesOpen,
    required this.disputesResolved,
  });

  final DateTime from;
  final DateTime to;

  /// Phase 4 (4.2) — the per-day/month time series, bucketed
  /// client-side from the rows this report fetched.
  final List<AdminReportPoint> series;

  /// True when the 1,000-row fetch cap may have cut rows off: the
  /// KPIs and charts then cover only the first 1,000 rows, and the
  /// view says so instead of presenting partial totals as complete.
  final bool bookingsTruncated;
  final bool transfersTruncated;

  final int totalBookings;
  final int completedBookings;
  final int bookingRevenue;
  final Map<String, int> bookingsByCity;
  final List<MapEntry<String, int>> topShops;
  final int financeIncome;
  final int financeExpense;
  final Map<String, int> incomeByCategory;
  final Map<String, int> expenseByCategory;
  final int newCustomers;
  final int disputesOpen;
  final int disputesResolved;
}
