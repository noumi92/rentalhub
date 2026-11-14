import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { authenticator } from "otplib";

// ---------------------------------------------------------------------------
// Phase A — Admin foundations: TOTP 2FA, admin team roles, audit logging.
// v2 API style (firebase-functions v6), matching this repo's index.ts.
//
// Ported from the old repo (noumi92/renthub Batch 14, admin.ts) and
// adapted:
// - v1 onCall/context.auth -> v2 onCall/request.auth.
// - Admin status is the users doc `admin_role` field OR the custom
//   claim (role: 'admin'). The first super admin is created manually
//   in Firebase Auth with `admin_role: 'super_admin'` on their users
//   doc (plan D1) and holds NO custom claim yet — so every function
//   below accepts the doc role, and setAdminRole stamps the claim on
//   such a caller once (bootstrap), instead of the old code's
//   claim-only bootstrap.
// - The invite requirement for grants is unchanged (48 h expiry).
// ---------------------------------------------------------------------------

const db = admin.firestore();

// Allow one 30-second step of clock skew either way when checking codes.
authenticator.options = { window: 1 };

type AdminRole = "super_admin" | "operations" | "support";

const ADMIN_ROLES: AdminRole[] = ["super_admin", "operations", "support"];

function isAdminRole(value: unknown): value is AdminRole {
  return typeof value === "string" && (ADMIN_ROLES as string[]).includes(value);
}

function denied(message: string): never {
  throw new HttpsError("permission-denied", message);
}

function invalid(message: string): never {
  throw new HttpsError("invalid-argument", message);
}

/** Shared audit writer. audit_logs is immutable in Firestore rules
 * (read admin, create authenticated, update/delete never), so a record
 * written here can never be edited afterwards. Shape matches the
 * app-side AdminAuditService. */
async function writeAuditLog(entry: {
  action: string;
  actorId: string;
  actorEmail: string;
  targetType: string;
  targetId: string;
  detail?: string;
}): Promise<void> {
  await db.collection("audit_logs").add({
    type: "admin_action",
    action: entry.action,
    actor_id: entry.actorId,
    actor_email: entry.actorEmail,
    target_type: entry.targetType,
    target_id: entry.targetId,
    detail: entry.detail ?? "",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** The caller's admin role from their users doc, falling back to the
 * custom claim. Null when they hold neither. */
async function callerAdminRole(
  uid: string,
  token: Record<string, unknown> | undefined
): Promise<AdminRole | null> {
  const doc = await db.collection("users").doc(uid).get();
  const docRole = doc.data()?.admin_role as unknown;
  if (isAdminRole(docRole)) return docRole;
  if (token?.role === "admin" && isAdminRole(token?.admin_role)) {
    return token.admin_role as AdminRole;
  }
  return null;
}

/**
 * Callable: start TOTP enrolment for the calling admin.
 * Generates a fresh secret, stores it PENDING in admin_secrets/{uid}
 * (verified: false), and returns the otpauth:// URL ONCE so the admin
 * can scan it into an authenticator app. The secret is never readable
 * from Firestore by any client — Firestore rules deny all client access
 * to admin_secrets; only the Admin SDK (these functions) reads it.
 */
export const enrollTotp = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const uid = request.auth.uid;
  const role = await callerAdminRole(uid, request.auth.token);
  if (role === null) {
    denied("Only admins may enrol TOTP.");
  }
  const existing = await db.collection("admin_secrets").doc(uid).get();
  if (existing.exists && existing.data()?.verified === true) {
    throw new HttpsError(
      "already-exists",
      "TOTP is already enrolled for this admin. Ask a super admin to reset it first."
    );
  }
  const secret = authenticator.generateSecret();
  const account = request.auth.token.email ?? uid;
  const otpauthUrl = authenticator.keyuri(account, "RentalHub Admin", secret);
  await db.collection("admin_secrets").doc(uid).set(
    {
      secret,
      verified: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return { otpauthUrl };
});

/**
 * Callable: verify a 6-digit TOTP code for the calling admin.
 * Used both at login (after password sign-in) and to complete enrolment:
 * if the stored secret is still pending (verified: false) and the code is
 * right, enrolment completes — users/{uid} gains totp_enabled: true and
 * totp_enrolled_at, and the enrolment is written to the audit log.
 * A wrong or expired code fails with a plain message; nothing is written.
 */
export const verifyTotp = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const uid = request.auth.uid;
  const code = String(request.data.code ?? "").trim();
  if (!/^\d{6}$/.test(code)) {
    invalid("Enter the 6-digit code from your authenticator app.");
  }
  const secretDoc = await db.collection("admin_secrets").doc(uid).get();
  if (!secretDoc.exists) {
    throw new HttpsError(
      "failed-precondition",
      "TOTP is not set up for this admin yet."
    );
  }
  const secret = secretDoc.data()?.secret as string | undefined;
  if (!secret) {
    throw new HttpsError(
      "failed-precondition",
      "TOTP is not set up for this admin yet."
    );
  }
  const ok = authenticator.verify({ token: code, secret });
  if (!ok) {
    denied("That code is wrong or has expired. Try the current code.");
  }
  const wasPending = secretDoc.data()?.verified !== true;
  if (wasPending) {
    const now = admin.firestore.FieldValue.serverTimestamp();
    await secretDoc.ref.update({ verified: true, verified_at: now });
    await db.collection("users").doc(uid).update({
      totp_enabled: true,
      totp_enrolled_at: now,
    });
    await writeAuditLog({
      action: "totp_enrolled",
      actorId: uid,
      actorEmail: request.auth.token.email ?? "",
      targetType: "admin",
      targetId: uid,
      detail: "TOTP two-factor authentication enrolled.",
    });
    return { success: true, enrolled: true };
  }
  return { success: true, enrolled: false };
});

/**
 * Callable: reset TOTP for another admin (super admin only).
 * Deletes the stored secret and clears totp_enabled, so the admin is
 * forced through enrolment again on their next login.
 */
export const resetTotp = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const callerUid = request.auth.uid;
  const callerRole = await callerAdminRole(callerUid, request.auth.token);
  if (callerRole !== "super_admin") {
    denied("Only a super admin can reset another admin's two-factor authentication.");
  }
  const targetUid = request.data.uid as string | undefined;
  if (!targetUid) invalid("uid is required.");
  await db.collection("admin_secrets").doc(targetUid).delete();
  await db.collection("users").doc(targetUid).update({
    totp_enabled: false,
    totp_enrolled_at: admin.firestore.FieldValue.delete(),
  });
  await writeAuditLog({
    action: "totp_reset",
    actorId: callerUid,
    actorEmail: request.auth.token.email ?? "",
    targetType: "admin",
    targetId: targetUid,
    detail: "TOTP reset by a super admin; the admin must enrol again on next login.",
  });
  return { success: true };
});

/**
 * Callable: grant or revoke an admin role.
 * Grant — data: { email, adminRole } where adminRole is one of
 * 'super_admin' | 'operations' | 'support'. Revoke — data: { uid } or
 * { email } with adminRole: null.
 *
 * Only a super admin may call this. The caller's super-admin status is
 * read from their users doc (admin_role == 'super_admin') or the custom
 * claim. Bootstrap: a caller who holds the doc role but no custom claim
 * yet (the manually created first super admin, plan D1) is treated as
 * super admin once, and the claim is stamped on them so the exception
 * is one-time.
 *
 * A grant requires a matching, unexpired, unaccepted invite in
 * admin_invites (email + role must match, created within 48 hours).
 * The invite is marked accepted. The target's custom claims become
 * { role: 'admin', admin_role: <role> } and their users doc gains
 * role: 'admin' + admin_role. A revoke clears the claims, sets the doc
 * role back to 'customer', deletes admin_role, deletes any stored TOTP
 * secret and clears totp_enabled. Every grant/revoke is audit-logged.
 * Usage (from the admin app):
 *   FirebaseFunctions.instance.httpsCallable('setAdminRole')
 *     .call({'email': targetEmail, 'adminRole': 'operations'})
 */
export const setAdminRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first.");
  }
  const callerUid = request.auth.uid;
  let callerRole = await callerAdminRole(callerUid, request.auth.token);
  if (callerRole === null) {
    denied("Only existing admins may grant admin roles.");
  }
  // Bootstrap: the manually created first super admin (plan D1) holds
  // the doc role but no custom claim yet. Stamp the claim once.
  if (request.auth.token.role !== "admin") {
    await admin.auth().setCustomUserClaims(callerUid, {
      role: "admin",
      admin_role: callerRole,
    });
  }
  if (callerRole !== "super_admin") {
    denied("Only a super admin can manage admin roles.");
  }

  const adminRoleRaw = request.data.adminRole as unknown;
  const isRevoke = adminRoleRaw === null || adminRoleRaw === undefined;
  const adminRole: AdminRole | null = isRevoke
    ? null
    : isAdminRole(adminRoleRaw)
      ? adminRoleRaw
      : invalid("adminRole must be 'super_admin', 'operations', 'support', or null to revoke.");

  // Resolve the target user by email (invite flow) or uid.
  let targetUid = request.data.uid as string | undefined;
  let targetEmail = request.data.email as string | undefined;
  if (!targetUid && !targetEmail) invalid("uid or email is required.");
  if (targetUid && !targetEmail) {
    const userRecord = await admin.auth().getUser(targetUid);
    targetEmail = userRecord.email;
  }
  if (!targetEmail) invalid("The target account has no email address.");
  if (!targetUid) {
    const userRecord = await admin.auth().getUserByEmail(targetEmail);
    targetUid = userRecord.uid;
  }

  if (adminRole !== null) {
    // Grant: a valid invite must exist for this email + role.
    const invites = await db
      .collection("admin_invites")
      .where("email", "==", targetEmail)
      .get();
    const now = Date.now();
    const invite = invites.docs.find((doc) => {
      const d = doc.data();
      return (
        d.admin_role === adminRole &&
        d.accepted !== true &&
        typeof d.expires_at?.toMillis === "function" &&
        (d.expires_at as admin.firestore.Timestamp).toMillis() > now
      );
    });
    if (!invite) {
      throw new HttpsError(
        "failed-precondition",
        "No valid invite for this email and role. Create an invite first — invites expire after 48 hours."
      );
    }
    await invite.ref.update({
      accepted: true,
      accepted_at: admin.firestore.FieldValue.serverTimestamp(),
      accepted_by: callerUid,
    });
    await admin.auth().setCustomUserClaims(targetUid, {
      role: "admin",
      admin_role: adminRole,
    });
    await db.collection("users").doc(targetUid).set(
      { role: "admin", admin_role: adminRole },
      { merge: true }
    );
    await writeAuditLog({
      action: "admin_role_granted",
      actorId: callerUid,
      actorEmail: request.auth.token.email ?? "",
      targetType: "admin",
      targetId: targetUid,
      detail: `Granted ${adminRole} to ${targetEmail}.`,
    });
    return { success: true, message: `${adminRole} granted to ${targetEmail}` };
  }

  // Revoke: no invite needed.
  await admin.auth().setCustomUserClaims(targetUid, {});
  await db.collection("users").doc(targetUid).update({
    role: "customer",
    admin_role: admin.firestore.FieldValue.delete(),
    totp_enabled: false,
    totp_enrolled_at: admin.firestore.FieldValue.delete(),
  });
  await db.collection("admin_secrets").doc(targetUid).delete().catch(() => undefined);
  await writeAuditLog({
    action: "admin_role_revoked",
    actorId: callerUid,
    actorEmail: request.auth.token.email ?? "",
    targetType: "admin",
    targetId: targetUid,
    detail: `Admin role revoked from ${targetEmail}; account is a customer again.`,
  });
  return { success: true, message: `Admin role revoked from ${targetEmail}` };
});

/**
 * Scheduled: 2-year retention for the immutable audit log.
 * Deletes audit_logs entries older than 2 years (500 per run).
 * Runs daily at 02:00. Deletion here is deliberate and server-side —
 * the Firestore rules still forbid any client from updating or deleting
 * a log entry.
 */
export const pruneAuditLogs = onSchedule("every day 02:00", async () => {
  const cutoffMillis = Date.now() - 2 * 365 * 24 * 60 * 60 * 1000;
  const cutoff = admin.firestore.Timestamp.fromMillis(cutoffMillis);
  const old = await db
    .collection("audit_logs")
    .where("created_at", "<", cutoff)
    .orderBy("created_at")
    .limit(500)
    .get();
  if (old.empty) return;
  const batch = db.batch();
  old.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`Pruned ${old.size} audit log entries older than 2 years.`);
});

/**
 * Admin audit (2026-11-14, F-m4): expired invites lingered forever
 * in the team list. The client prunes on team load, and this
 * scheduled function is the backstop — deletes unaccepted invites
 * whose expires_at has passed (500 per run), daily at 02:30.
 *
 * Deploy note: like every Function in this file, this only runs
 * once deployed (`firebase deploy --only functions`), which is
 * blocked on the billing account (user postponed 2026-11-10).
 * Until then the client-side prune is the only one running.
 */
export const pruneExpiredInvites = onSchedule("every day 02:30", async () => {
  const old = await db
    .collection("admin_invites")
    .where("accepted", "==", false)
    .where("expires_at", "<", admin.firestore.Timestamp.now())
    .limit(500)
    .get();
  if (old.empty) return;
  const batch = db.batch();
  old.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`Pruned ${old.size} expired admin invites.`);
});

/**
 * Phase E (E3): send an announcement.
 *
 * Callable, admin-only (doc role or claim, same gate as the other
 * admin functions). Reads announcements/{announcementId} and delivers
 * it:
 * - Push channel: FCM multicast to the tokens the app registers on
 *   users/{uid}.fcm_token, filtered by the announcement's audience
 *   (role all/owner/customer; owners can also be filtered by city
 *   and plan via their shops document). `test: true` sends only to
 *   the calling admin's own token.
 * - WhatsApp channel: NOT sent here — delivery waits for the Meta
 *   token (plan D2). The announcement is marked `pending_whatsapp`
 *   so the UI never claims a WhatsApp delivery that did not happen.
 * - Both channels: push goes out now; WhatsApp stays pending.
 *
 * The announcement's stats_sent is the real FCM success count.
 * stats_delivered stays 0 — FCM delivery receipts are not reported
 * by the app, and the count is never estimated. stats_opened is
 * incremented by the app when the announcement detail screen is
 * opened (see AnnouncementDetailView).
 *
 * F-M14 (admin audit 2026-11-14): the delivery core lives in
 * [deliverAnnouncement] so the scheduled dispatcher below
 * ([sendDueAnnouncements]) sends due announcements with the same
 * code path. A non-test send is refused when the announcement is
 * already `sent` or `pending_whatsapp` (push already delivered) —
 * the client disables "Send now" for those states, and this guard
 * is the backstop against a double push via a direct call.
 */
export const sendAnnouncement = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in as an admin first.");
  }
  const role = await callerAdminRole(callerUid, request.auth?.token);
  if (role === null) {
    throw new HttpsError(
      "permission-denied",
      "Only an admin can send announcements."
    );
  }

  const announcementId = request.data?.announcementId as string | undefined;
  const test = request.data?.test === true;
  if (!announcementId) {
    throw new HttpsError("invalid-argument", "announcementId is required.");
  }
  return deliverAnnouncement({
    announcementId,
    test,
    actorId: callerUid,
    actorEmail: request.auth?.token.email ?? "",
  });
});

/**
 * Scheduled: send announcements whose time has come (F-M14).
 * Every 15 minutes, picks up `status == 'scheduled'` announcements
 * with `scheduled_at` at or before now and delivers each with the
 * same [deliverAnnouncement] path the admin's "Send now" uses, then
 * marks them `sent` / `pending_whatsapp`. Without this dispatcher
 * a scheduled announcement sat forever — scheduling was a label.
 * A due announcement that fails to send is left `scheduled` with
 * the error logged, so the next run retries it instead of silently
 * dropping it.
 *
 * DEPLOY DEPENDENCY: this is a Cloud Function — it only runs once
 * the Functions are deployed (`firebase deploy --only functions`),
 * which needs the billing account (Cloud Build + Artifact Registry).
 * Until then, scheduled announcements still need a manual "Send
 * now" from the admin panel. Never fake a send.
 */
export const sendDueAnnouncements = onSchedule(
  "every 15 minutes",
  async () => {
    const now = Date.now();
    const due = await db
      .collection("announcements")
      .where("status", "==", "scheduled")
      .get();
    for (const doc of due.docs) {
      const data = doc.data();
      const scheduledAt = data.scheduled_at;
      let scheduledMillis: number | null = null;
      if (typeof scheduledAt?.toMillis === "function") {
        scheduledMillis = (scheduledAt as admin.firestore.Timestamp).toMillis();
      } else if (typeof scheduledAt === "string") {
        const parsed = Date.parse(scheduledAt);
        scheduledMillis = Number.isNaN(parsed) ? null : parsed;
      }
      if (scheduledMillis === null || scheduledMillis > now) continue;
      try {
        await deliverAnnouncement({
          announcementId: doc.id,
          test: false,
          actorId: "scheduled",
          actorEmail: "scheduled@rentalhub",
        });
        console.log(`Scheduled announcement ${doc.id} sent.`);
      } catch (e) {
        console.error(
          `Scheduled announcement ${doc.id} failed, will retry next run:`,
          e
        );
      }
    }
  }
);

/** The shared delivery core for [sendAnnouncement] and
 * [sendDueAnnouncements]. [actorId]/[actorEmail] are the caller for
 * a manual send, or 'scheduled' for the dispatcher. */
async function deliverAnnouncement(args: {
  announcementId: string;
  test: boolean;
  actorId: string;
  actorEmail: string;
}): Promise<{
  success: boolean;
  sent: number;
  whatsappPending: boolean;
  message: string;
}> {
  const { announcementId, test, actorId, actorEmail } = args;
  const announcementRef = db.collection("announcements").doc(announcementId);
  const announcementSnap = await announcementRef.get();
  if (!announcementSnap.exists) {
    throw new HttpsError("not-found", "Announcement not found.");
  }
  const announcement = announcementSnap.data()!;

  // F-M14 re-send guard: push already went out for these states.
  // A test send (admin's own device only) is always allowed.
  const status = announcement.status as string | undefined;
  if (
    !test &&
    (status === "sent" || status === "pending_whatsapp")
  ) {
    throw new HttpsError(
      "failed-precondition",
      "This announcement was already sent."
    );
  }

  const channel = announcement.channel as string | undefined;
  const audienceRole = announcement.audience_role as string | undefined ?? "all";
  const audienceCity = announcement.audience_city as string | undefined ?? "all";
  const audiencePlan = announcement.audience_plan as string | undefined ?? "all";
  const title = (announcement.title_en as string | undefined) ?? "RentalHub";
  const body = (announcement.body_en as string | undefined) ?? "";

  let sent = 0;
  if (channel === "push" || channel === "both") {
    // Resolve the audience to FCM tokens.
    const tokens: string[] = [];
    if (test) {
      const me = await db.collection("users").doc(actorId).get();
      const token = me.data()?.fcm_token as string | undefined;
      if (token) tokens.push(token);
    } else if (audienceRole === "customer") {
      const users = await db
        .collection("users")
        .where("role", "==", "customer")
        .get();
      users.forEach((doc) => {
        const token = doc.data().fcm_token as string | undefined;
        if (token) tokens.push(token);
      });
    } else {
      // Owners (or everyone): resolve through the shops collection so
      // city and plan filters can apply.
      let shopsQuery: FirebaseFirestore.Query = db.collection("shops");
      if (audienceCity !== "all") {
        shopsQuery = shopsQuery.where("city", "==", audienceCity);
      }
      if (audiencePlan !== "all") {
        shopsQuery = shopsQuery.where("plan", "==", audiencePlan);
      }
      const shops = await shopsQuery.get();
      const ownerUids = new Set<string>();
      shops.forEach((doc) => {
        const ownerId = doc.data().owner_id as string | undefined;
        if (ownerId) ownerUids.add(ownerId);
      });
      if (audienceRole === "all") {
        const customers = await db
          .collection("users")
          .where("role", "==", "customer")
          .get();
        customers.forEach((doc) => ownerUids.add(doc.id));
      }
      for (const uid of ownerUids) {
        const userDoc = await db.collection("users").doc(uid).get();
        const token = userDoc.data()?.fcm_token as string | undefined;
        if (token) tokens.push(token);
      }
    }

    if (tokens.length > 0) {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: { announcementId },
      });
      sent = response.successCount;
      console.log(
        `Announcement ${announcementId}: FCM sent to ${sent}/${tokens.length} tokens.`
      );
    }
  }

  const whatsappPending = channel === "whatsapp" || channel === "both";
  await announcementRef.update({
    status: whatsappPending ? "pending_whatsapp" : "sent",
    stats_sent: sent,
    sent_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  await writeAuditLog({
    action: "announcement_sent",
    actorId,
    actorEmail,
    targetType: "announcement",
    targetId: announcementId,
    detail: `Channel ${channel}, audience ${audienceRole}/${audienceCity}/${audiencePlan}, FCM sent ${sent}${whatsappPending ? ", WhatsApp pending (D2 token)" : ""}.`,
  });
  return {
    success: true,
    sent,
    whatsappPending,
    message: whatsappPending
      ? `Push sent to ${sent} device(s). WhatsApp delivery is pending the Meta token (plan D2).`
      : `Push sent to ${sent} device(s).`,
  };
}
