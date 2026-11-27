import * as admin from 'firebase-admin';
export { onBookingUpdated } from './triggers/on_booking_updated';
export { deleteUserAccount } from './delete_user_account';
export {
  enrollTotp,
  verifyTotp,
  resetTotp,
  setAdminRole,
  pruneAuditLogs,
  sendAnnouncement,
  sendDueAnnouncements,
} from './admin';

admin.initializeApp();
