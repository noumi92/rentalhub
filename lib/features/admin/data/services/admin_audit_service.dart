import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Phase A (A5) — shared writer for the top-level `audit_logs`
/// collection, ported from the old repo (noumi92/renthub Batch 14).
///
/// Shape (matches the Cloud Functions writer in
/// backend/functions/src/admin.ts): {type: 'admin_action', action,
/// actor_id, actor_email, target_type, target_id, detail, decision,
/// created_at}.
///
/// audit_logs is immutable in Firestore rules (read admin, create
/// authenticated, update/delete never), so a record written here can
/// never be edited afterwards. Logging must never break the action it
/// records, so failures are swallowed.
abstract final class AdminAuditService {
  static Future<void> logAction({
    required String action,
    required String targetType,
    required String targetId,
    String? detail,
    String? decision,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'type': 'admin_action',
        'action': action,
        'actor_id': user.uid,
        'actor_email': user.email ?? '',
        'target_type': targetType,
        'target_id': targetId,
        'detail': detail ?? '',
        if (decision != null) 'decision': decision,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Audit logging must never fail the admin action itself.
    }
  }
}
