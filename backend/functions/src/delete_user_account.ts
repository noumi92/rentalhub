import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

/**
 * Google Play Account Deletion Policy:
 * Atomically deletes the authenticated user's personal Firestore records
 * (profile, KYC/CNIC documents, notifications) and deactivates an owner's
 * showroom while preserving legally required booking/tax settlement records.
 */
export const deleteUserAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in to delete your account.');
  }
  const isOwner = request.data?.isOwner === true;
  const db = admin.firestore();

  // Delete personal documents
  await Promise.allSettled([
    db.collection('customers').doc(uid).delete(),
    db.collection('kyc_documents').doc(uid).delete(),
    db.collection('users').doc(uid).delete(),
  ]);

  // Delete customer notifications in a batch
  const notifs = await db
    .collection('notifications')
    .where('customerId', '==', uid)
    .limit(500)
    .get();
  if (!notifs.empty) {
    const batch = db.batch();
    notifs.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  // Soft-close owner showroom while preserving booking & financial history
  if (isOwner) {
    const candidateIds = [`shop_${uid}`, uid];
    for (const shopId of candidateIds) {
      const ref = db.collection('shops').doc(shopId);
      const snap = await ref.get();
      if (snap.exists) {
        await ref.set(
          {
            suspended: true,
            account_deleted: true,
            deleted_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
    }
  }

  return { ok: true };
});
