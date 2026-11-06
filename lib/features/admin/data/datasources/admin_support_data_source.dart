import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../bookings/data/models/booking_model.dart';
import '../../../finance/data/models/finance_transfer_model.dart';
import '../services/admin_audit_service.dart';

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

  Future<List<SupportTicket>> getTickets({String status = 'all'}) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      var query = firestore.collection('support_tickets').limit(100);
      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }
      final snap = await query.get();
      final list =
          snap.docs.map((d) => SupportTicket.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<TicketMessage>> getTicketReplies(String ticketId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('replies')
          .orderBy('created_at')
          .get();
      return snap.docs
          .map((d) => TicketMessage.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TicketMessage>> getTicketNotes(String ticketId) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('internal_notes')
          .orderBy('created_at')
          .get();
      return snap.docs
          .map((d) => TicketMessage.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> replyToTicket({
    required String ticketId,
    required String text,
  }) async {
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
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addTicketNote({
    required String ticketId,
    required String text,
  }) async {
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
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setTicketStatus({
    required String ticketId,
    required String status,
  }) async {
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

  Future<PlatformSettings> getPlatformSettings() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return const PlatformSettings();
    try {
      final doc = await firestore
          .collection('platform_settings')
          .doc('global')
          .get();
      final data = doc.data();
      if (data == null) return const PlatformSettings();
      return PlatformSettings.fromMap(data);
    } catch (_) {
      return const PlatformSettings();
    }
  }

  Future<bool> savePlatformSettings(PlatformSettings settings) async {
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

  Future<List<AdminAnnouncement>> getAnnouncements() async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return [];
    try {
      final snap = await firestore
          .collection('announcements')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();
      return snap.docs
          .map((d) => AdminAnnouncement.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

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
  }) async {
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
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  /// Sends an announcement through the `sendAnnouncement` Cloud
  /// Function. `test: true` delivers only to the calling admin's own
  /// device. Returns the Function's result map, or null when the
  /// call could not be made.
  Future<Map<String, dynamic>?> sendAnnouncement({
    required String announcementId,
    bool test = false,
  }) async {
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

  // ---- E4: reports ----

  Future<AdminReport?> getReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final firestore = _resolvedFirestore;
    if (firestore == null) return null;
    try {
      final bookingsSnap = await firestore.collection('bookings').get();
      final bookings = bookingsSnap.docs
          .map((d) => BookingModel.fromMap(d.data(), d.id))
          .where((b) =>
              !b.pickupTime.isBefore(from) && !b.pickupTime.isAfter(to))
          .toList();

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

      final transfersSnap =
          await firestore.collection('finance_transfers').get();
      var income = 0;
      var expense = 0;
      final incomeByCategory = <String, int>{};
      final expenseByCategory = <String, int>{};
      for (final d in transfersSnap.docs) {
        final t = FinanceTransferModel.fromMap(d.data());
        if (t.createdAt.isBefore(from) || t.createdAt.isAfter(to)) {
          continue;
        }
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

      final customersSnap = await firestore.collection('customers').get();
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
            !createdAt.isBefore(from) &&
            !createdAt.isAfter(to)) {
          newCustomers++;
        }
      }

      final disputesSnap = await firestore.collection('disputes').get();
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
            createdAt.isBefore(from) ||
            createdAt.isAfter(to)) {
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
        from: from,
        to: to,
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
      return null;
    }
  }

  static String reportCsv(AdminReport report) {
    final lines = <String>[
      'RentalHub platform report,${report.from.toIso8601String()},${report.to.toIso8601String()}',
      'Total bookings,${report.totalBookings}',
      'Completed bookings,${report.completedBookings}',
      'Booking revenue (Rs.),${report.bookingRevenue}',
      'Finance income (Rs.),${report.financeIncome}',
      'Finance expense (Rs.),${report.financeExpense}',
      'New customers,${report.newCustomers}',
      'Disputes open,${report.disputesOpen}',
      'Disputes resolved,${report.disputesResolved}',
      '',
      'Bookings by city',
      ...report.bookingsByCity.entries.map((e) => '${e.key},${e.value}'),
      '',
      'Top shops',
      ...report.topShops.map((e) => '${e.key},${e.value}'),
    ];
    return lines.join('\n');
  }
}

/// One support ticket (E1). Priority comes from the customer form
/// (High/Medium/Low); tickets filed before the form had a priority
/// default to Medium, so the SLA is never invented.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.customerId,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String message;
  final String status;
  final String priority;
  final DateTime? createdAt;

  int get slaHours =>
      switch (priority.toLowerCase()) { 'high' => 1, 'low' => 24, _ => 4 };

  String slaText() {
    if (createdAt == null) return 'SLA: filed date unknown';
    final left =
        createdAt!.add(Duration(hours: slaHours)).difference(DateTime.now());
    if (left.isNegative) return 'SLA breached by ${-left.inHours}h';
    return '${left.inHours}h of ${slaHours}h SLA left';
  }

  factory SupportTicket.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return SupportTicket(
      id: id,
      customerId: data['customerId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      priority: data['priority'] as String? ?? 'medium',
      createdAt: createdAt,
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
  });

  final List<String> liveCities;
  final List<String> carCategories;
  final int advancePercent;
  final int defaultDepositPkr;
  final int lateGraceMinutes;
  final String supportHours;
  final String defaultAgreementTerms;
  final bool maintenanceMode;

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
    };
  }
}

/// One announcement (E3). Stats: `sent` is real (the Function's
/// delivery count); `delivered`/`opened` stay 0 until the app reports
/// them — they are never estimated.
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
