import * as admin from 'firebase-admin';
export { onBookingUpdated } from './triggers/on_booking_updated';
export {
  enrollTotp,
  verifyTotp,
  resetTotp,
  setAdminRole,
  pruneAuditLogs,
  sendAnnouncement,
} from './admin';

admin.initializeApp();
