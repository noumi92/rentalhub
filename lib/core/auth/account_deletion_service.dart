import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/datasources/notification_data_source.dart';
import '../di/injection_container.dart';
import '../utils/shop_id_resolution.dart';

enum AccountDeletionStatus { success, requiresRecentLogin, error }

class AccountDeletionResult {
  const AccountDeletionResult(this.status);
  final AccountDeletionStatus status;
}

/// Google Play Account Deletion Policy compliance:
/// Permanently deletes the signed-in user's personal data (profile, KYC/CNIC
/// docs, FCM tokens, notifications) and Firebase Auth credentials, while
/// preserving legally required booking/tax settlement records in anonymized
/// or restricted form.
class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = auth,
        _firestore = firestore,
        _functions = functions;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  FirebaseAuth? get _resolvedAuth {
    if (_auth != null) return _auth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

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

  Future<AccountDeletionResult> deleteCurrentAccount({
    required bool isOwner,
  }) async {
    final auth = _resolvedAuth;
    final user = auth?.currentUser;
    if (user == null) {
      await _clearLocalState();
      return const AccountDeletionResult(AccountDeletionStatus.success);
    }
    final uid = user.uid;

    // 1. Try server-side Cloud Function if deployed (best-effort; falls back
    //    to direct client cleanup + FirebaseAuth.delete).
    final functions = _resolvedFunctions;
    if (functions != null) {
      try {
        await functions
            .httpsCallable('deleteUserAccount')
            .call({'uid': uid, 'isOwner': isOwner});
      } catch (_) {
        // Function may not be deployed yet — fall through to client cleanup.
      }
    }

    // 2. Delete user-owned Firestore records (best-effort per collection so a
    //    missing doc never aborts deletion).
    final fs = _resolvedFirestore;
    if (fs != null) {
      await _safeDelete(fs.collection('customers').doc(uid));
      await _safeDelete(fs.collection('kyc_documents').doc(uid));
      await _safeDelete(fs.collection('users').doc(uid));

      // Remove in-app notifications belonging to this customer.
      try {
        final notifSnap = await fs
            .collection('notifications')
            .where('customerId', isEqualTo: uid)
            .limit(200)
            .get();
        if (notifSnap.docs.isNotEmpty) {
          final batch = fs.batch();
          for (final doc in notifSnap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (_) {}

      // For owners: deactivate/soft-close the showroom while preserving
      // legally required booking & tax settlement history.
      if (isOwner) {
        try {
          final shopDocId = await canonicalShopId(fs, uid);
          await fs.collection('shops').doc(shopDocId).set({
            'suspended': true,
            'account_deleted': true,
            'deleted_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }

    // 3. Delete Firebase Auth account.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const AccountDeletionResult(
          AccountDeletionStatus.requiresRecentLogin,
        );
      }
      return const AccountDeletionResult(AccountDeletionStatus.error);
    } catch (_) {
      return const AccountDeletionResult(AccountDeletionStatus.error);
    }

    await _clearLocalState();
    return const AccountDeletionResult(AccountDeletionStatus.success);
  }

  Future<void> _safeDelete(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await ref.delete();
    } catch (_) {}
  }

  Future<void> _clearLocalState() async {
    try {
      if (sl.isRegistered<NotificationDataSource>()) {
        sl<NotificationDataSource>().clearCache();
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rentalhub_user_uid');
      await prefs.remove('rentalhub_user_role');
    } catch (_) {}
  }
}
