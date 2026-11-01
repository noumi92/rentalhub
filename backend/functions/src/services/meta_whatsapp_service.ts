import axios from 'axios';

const META_ACCESS_TOKEN = process.env.META_PERMANENT_ACCESS_TOKEN || '';
const META_PHONE_NUMBER_ID = process.env.META_PHONE_NUMBER_ID || '';

export async function dispatchAgreementWhatsAppTemplate(params: {
  customerPhone: string;
  customerName: string;
  vehicleName: string;
  agreementPdfUrl: string;
}): Promise<number> {
  const response = await axios.post(
    `https://graph.facebook.com/v20.0/${META_PHONE_NUMBER_ID}/messages`,
    {
      messaging_product: 'whatsapp',
      to: params.customerPhone,
      type: 'template',
      template: {
        name: 'rental_agreement_pdf_dispatch',
        language: { code: 'en_US' },
        components: [
          {
            type: 'body',
            parameters: [
              { type: 'text', text: params.customerName },
              { type: 'text', text: params.vehicleName },
              { type: 'text', text: params.agreementPdfUrl },
            ],
          },
        ],
      },
    },
    {
      headers: {
        Authorization: `Bearer ${META_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
      },
    }
  );
  return response.status;
}

