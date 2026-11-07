import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_engine.dart';
import 'sync_queue_entry.dart';

/// Phase B (B3/B4): the generic Firestore-write queue handler
/// (kind `'firestore_set'`).
///
/// Payload: `{collection, docId, fields}`. Writes the fields with
/// merge semantics + a server `updatedAt`, so a retry never
/// clobbers a concurrent change and ordering never depends on the
/// phone's clock. Used by every data source whose direct write
/// fails offline (fleet, finance, KYC records, ...).
class FirestoreSetHandler {
  final FirebaseFirestore? _firestore;

  FirestoreSetHandler({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? get _resolvedFirestore {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<bool> call(SyncQueueEntry entry, SyncEngine engine) async {
    final fs = _resolvedFirestore;
    if (fs == null) return false;
    final payload = entry.payload;
    final collection = payload['collection'] as String?;
    final docId = payload['docId'] as String?;
    if (collection == null ||
        collection.isEmpty ||
        docId == null ||
        docId.isEmpty) {
      return false;
    }
    try {
      final fields =
          Map<String, dynamic>.from(payload['fields'] as Map? ?? {});
      await fs.collection(collection).doc(docId).set(
        {
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
