import * as admin from 'firebase-admin';
export { onBookingUpdated } from './triggers/on_booking_updated';
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
