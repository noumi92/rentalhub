import * as functions from 'firebase-functions';
import { dispatchAgreementWhatsAppTemplate } from '../services/meta_whatsapp_service';

export const onBookingUpdated = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== 'on_trip' && after.status === 'on_trip') {
      await dispatchAgreementWhatsAppTemplate({
        customerPhone: after.customer_phone,
        customerName: after.customer_name,
        vehicleName: after.vehicle_name,
        agreementPdfUrl: after.agreement_pdf_url,
      });
    }
  });

