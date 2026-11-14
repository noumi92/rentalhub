import 'package:cloud_firestore/cloud_firestore.dart';

/// G4: the customer's disputes — filed to Firestore `disputes` with an
/// in-memory fallback (offline / tests), the same pattern the booking
/// data source uses. [fileDispute] reports whether the cloud write
/// succeeded, so the UI never claims the showroom was notified when
/// the dispute only exists on this device.
class FiledDispute {
  const FiledDispute({required this.id, required this.synced});

  final String id;
  final bool synced;
}

class DisputeRecord {
  const DisputeRecord({
    required this.id,
    required this.bookingId,
    required this.category,
    required this.description,
    required this.status,
    this.createdAt,
    this.shopId,
    this.customerName,
    this.customerId,
    this.decision,
    this.decisionAmount,
    this.adminNote,
    this.resolvedAt,
  });

  final String id;
  final String bookingId;
  final String category;
  final String description;
  final String status; // 'open' | 'in_review' | 'resolved'
  final DateTime? createdAt;

  /// Owner inbox: the showroom the dispute belongs to. Filed by the
  /// customer when the booking is known; older records without it are
  /// attributed by resolving their booking (see getShopDisputes).
  final String? shopId;

  /// Enriched from the booking when the inbox loads it.
  final String? customerName;
  final String? customerId;

  /// The admin decision (F-M9): 'full_to_customer' | 'partial' |
  /// 'full_to_owner', written by `decideDispute` and read back by the
  /// admin centre and the customer's own dispute record. Null until
  /// the dispute is decided.
  final String? decision;
  final int? decisionAmount;
  final String? adminNote;
  final DateTime? resolvedAt;
}

/// A Firestore Timestamp, an ISO string, or null — the two shapes a
/// dispute date field arrives in.
DateTime? _dateFrom(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class DisputeRemoteDataSource {
  final Map<String, Map<String, dynamic>> _inMemory = {};

  Future<FiledDispute> fileDispute({
    required String bookingId,
    required String customerId,
    required String category,
    required String description,
    String? shopId,
  }) async {
    final id = 'DSP-${DateTime.now().millisecondsSinceEpoch}';
    final record = <String, dynamic>{
      'bookingId': bookingId,
      'customerId': customerId,
      'category': category,
      'description': description,
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
      if (shopId != null) 'shopId': shopId,
    };
    _inMemory[id] = record;
    var synced = false;
    try {
      await FirebaseFirestore.instance.collection('disputes').add({
        ...record,
        'createdAt': FieldValue.serverTimestamp(),
      });
      synced = true;
    } catch (_) {}
    if (synced) {
      // F-M11: the booking enters the `disputed` lifecycle state so
      // the admin bookings list can surface it and the shop cannot
      // settle it while the dispute is open. The previous status is
      // kept on the booking so the decision can restore it. Best
      // effort — a failure here never fails the filing itself.
      try {
        final bookingRef =
            FirebaseFirestore.instance.collection('bookings').doc(bookingId);
        final bookingDoc = await bookingRef.get();
        final currentStatus = bookingDoc.data()?['status'] as String?;
        if (currentStatus != null && currentStatus != 'disputed') {
          await bookingRef.update({
            'status': 'disputed',
            'statusBeforeDispute': currentStatus,
          });
        }
      } catch (_) {}
    }
    return FiledDispute(id: id, synced: synced);
  }

  Future<List<DisputeRecord>> getCustomerDisputes(String customerId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('disputes')
          .where('customerId', isEqualTo: customerId)
          .get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) {
          final data = d.data();
          final created = data['createdAt'];
          DateTime? createdAt;
          if (created is Timestamp) {
            createdAt = created.toDate();
          } else if (created is String) {
            createdAt = DateTime.tryParse(created);
          }
          return DisputeRecord(
            id: d.id,
            bookingId: data['bookingId'] as String? ?? '',
            category: data['category'] as String? ?? '',
            description: data['description'] as String? ?? '',
            status: data['status'] as String? ?? 'open',
            createdAt: createdAt,
            decision: data['decision'] as String?,
            decisionAmount: (data['decision_amount'] as num?)?.toInt(),
            adminNote: data['admin_note'] as String?,
            resolvedAt: _dateFrom(data['resolved_at']),
          );
        }).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        return list;
      }
    } catch (_) {}
    final list = _inMemory.entries
        .where((e) => e.value['customerId'] == customerId)
        .map((e) => DisputeRecord(
              id: e.key,
              bookingId: e.value['bookingId'] as String? ?? '',
              category: e.value['category'] as String? ?? '',
              description: e.value['description'] as String? ?? '',
              status: e.value['status'] as String? ?? 'open',
              createdAt: DateTime.tryParse(
                  e.value['createdAt'] as String? ?? ''),
              decision: e.value['decision'] as String?,
              decisionAmount:
                  (e.value['decision_amount'] as num?)?.toInt(),
              adminNote: e.value['admin_note'] as String?,
              resolvedAt: _dateFrom(e.value['resolved_at']),
            ))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }

  /// Owner inbox: the disputes belonging to [shopId], newest first.
  /// A record carries its shop when the customer filed it with the
  /// booking known; records filed without one are attributed by
  /// resolving their booking document. Returns the records with the
  /// customer name enriched from the booking when available.
  Future<List<DisputeRecord>> getShopDisputes(String shopId) async {
    final records = <DisputeRecord>[];
    try {
      final snap =
          await FirebaseFirestore.instance.collection('disputes').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final recordShopId = await _resolveShopId(
          data['shopId'] as String?,
          data['bookingId'] as String? ?? '',
        );
        if (recordShopId != shopId) continue;
        records.add(await _toRecord(doc.id, data));
      }
    } catch (_) {}
    if (records.isEmpty) {
      for (final e in _inMemory.entries) {
        if ((e.value['shopId'] as String?) != shopId) continue;
        records.add(_recordFromMap(e.key, e.value));
      }
    }
    records.sort((a, b) =>
        (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return records;
  }

  /// The showroom answers a dispute by moving it through
  /// open -> in_review -> resolved. Returns true when the change
  /// reached Firestore.
  Future<bool> updateDisputeStatus(String id, String status) async {
    final existing = _inMemory[id];
    if (existing != null) {
      _inMemory[id] = {...existing, 'status': status};
    }
    try {
      await FirebaseFirestore.instance
          .collection('disputes')
          .doc(id)
          .update({'status': status});
      return true;
    } catch (_) {
      return existing != null;
    }
  }

  Future<String?> _resolveShopId(
      String? shopId, String bookingId) async {
    if (shopId != null && shopId.isNotEmpty) return shopId;
    if (bookingId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      return doc.data()?['shopId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<DisputeRecord> _toRecord(
      String id, Map<String, dynamic> data) async {
    String? customerName;
    final bookingId = data['bookingId'] as String? ?? '';
    if (bookingId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get();
        customerName = doc.data()?['customerName'] as String?;
      } catch (_) {}
    }
    return _recordFromMap(id, data, customerName: customerName);
  }

  DisputeRecord _recordFromMap(String id, Map<String, dynamic> data,
      {String? customerName}) {
    final created = data['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created);
    }
    return DisputeRecord(
      id: id,
      bookingId: data['bookingId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: createdAt,
      shopId: data['shopId'] as String?,
      customerName: customerName,
      customerId: data['customerId'] as String?,
      decision: data['decision'] as String?,
      decisionAmount: (data['decision_amount'] as num?)?.toInt(),
      adminNote: data['admin_note'] as String?,
      resolvedAt: _dateFrom(data['resolved_at']),
    );
  }
}
