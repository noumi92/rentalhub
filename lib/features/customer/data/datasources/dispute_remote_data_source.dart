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
  });

  final String id;
  final String bookingId;
  final String category;
  final String description;
  final String status; // 'open' | 'in_review' | 'resolved'
  final DateTime? createdAt;
}

class DisputeRemoteDataSource {
  final Map<String, Map<String, dynamic>> _inMemory = {};

  Future<FiledDispute> fileDispute({
    required String bookingId,
    required String customerId,
    required String category,
    required String description,
  }) async {
    final id = 'DSP-${DateTime.now().millisecondsSinceEpoch}';
    final record = <String, dynamic>{
      'bookingId': bookingId,
      'customerId': customerId,
      'category': category,
      'description': description,
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
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
            ))
        .toList();
    list.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list;
  }
}
