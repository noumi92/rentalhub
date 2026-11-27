import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsappAutoSettings {
  final bool bookingApproval;
  final bool advanceReceipt;
  final bool pickupReminder;
  final bool agreementPdf;
  final bool returnReminder;
  final bool depositRefunded;
  final bool duesReminder;

  const WhatsappAutoSettings({
    this.bookingApproval = true,
    this.advanceReceipt = true,
    this.pickupReminder = true,
    this.agreementPdf = true,
    this.returnReminder = true,
    this.depositRefunded = true,
    this.duesReminder = false,
  });

  factory WhatsappAutoSettings.fromMap(Map<String, dynamic> data) {
    bool flag(String key, bool fallback) =>
        (data[key] as bool?) ?? fallback;
    return WhatsappAutoSettings(
      bookingApproval: flag('bookingApproval', true),
      advanceReceipt: flag('advanceReceipt', true),
      pickupReminder: flag('pickupReminder', true),
      agreementPdf: flag('agreementPdf', true),
      returnReminder: flag('returnReminder', true),
      depositRefunded: flag('depositRefunded', true),
      duesReminder: flag('duesReminder', false),
    );
  }

  Map<String, dynamic> toMap() => {
        'bookingApproval': bookingApproval,
        'advanceReceipt': advanceReceipt,
        'pickupReminder': pickupReminder,
        'agreementPdf': agreementPdf,
        'returnReminder': returnReminder,
        'depositRefunded': depositRefunded,
        'duesReminder': duesReminder,
      };

  WhatsappAutoSettings copyWithKey(String key, bool value) => switch (key) {
        'bookingApproval' => WhatsappAutoSettings(
            bookingApproval: value,
            advanceReceipt: advanceReceipt,
            pickupReminder: pickupReminder,
            agreementPdf: agreementPdf,
            returnReminder: returnReminder,
            depositRefunded: depositRefunded,
            duesReminder: duesReminder),
        'advanceReceipt' => WhatsappAutoSettings(
            bookingApproval: bookingApproval,
            advanceReceipt: value,
            pickupReminder: pickupReminder,
            agreementPdf: agreementPdf,
            returnReminder: returnReminder,
            depositRefunded: depositRefunded,
            duesReminder: duesReminder),
        'pickupReminder' => WhatsappAutoSettings(
            bookingApproval: bookingApproval,
            advanceReceipt: advanceReceipt,
            pickupReminder: value,
            agreementPdf: agreementPdf,
            returnReminder: returnReminder,
            depositRefunded: depositRefunded,
            duesReminder: duesReminder),
        'agreementPdf' => WhatsappAutoSettings(
            bookingApproval: bookingApproval,
            advanceReceipt: advanceReceipt,
            pickupReminder: pickupReminder,
            agreementPdf: value,
            returnReminder: returnReminder,
            depositRefunded: depositRefunded,
            duesReminder: duesReminder),
        'returnReminder' => WhatsappAutoSettings(
            bookingApproval: bookingApproval,
            advanceReceipt: advanceReceipt,
            pickupReminder: pickupReminder,
            agreementPdf: agreementPdf,
            returnReminder: value,
            depositRefunded: depositRefunded,
            duesReminder: duesReminder),
        'depositRefunded' => WhatsappAutoSettings(
            bookingApproval: bookingApproval,
            advanceReceipt: advanceReceipt,
            pickupReminder: pickupReminder,
            agreementPdf: agreementPdf,
            returnReminder: returnReminder,
            depositRefunded: value,
            duesReminder: duesReminder),
        _ => WhatsappAutoSettings(
            bookingApproval: bookingApproval,
            advanceReceipt: advanceReceipt,
            pickupReminder: pickupReminder,
            agreementPdf: agreementPdf,
            returnReminder: returnReminder,
            depositRefunded: depositRefunded,
            duesReminder: value),
      };
}

class CreditPurchaseRequest {
  final int pack;
  final int amount;
  final String transactionId;
  final String status;
  final DateTime? createdAt;

  const CreditPurchaseRequest({
    required this.pack,
    required this.amount,
    required this.transactionId,
    required this.status,
    this.createdAt,
  });

  factory CreditPurchaseRequest.fromMap(Map<String, dynamic> data) {
    final created = data['createdAt'];
    return CreditPurchaseRequest(
      pack: (data['pack'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      transactionId: (data['transactionId'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

class WhatsappDispatchLog {
  final String recipientName;
  final String phone;
  final String messageType;
  final String category;
  final String status;
  final DateTime? sentAt;

  const WhatsappDispatchLog({
    required this.recipientName,
    required this.phone,
    required this.messageType,
    required this.category,
    required this.status,
    this.sentAt,
  });

  factory WhatsappDispatchLog.fromMap(Map<String, dynamic> data) {
    final sent = data['sentAt'];
    return WhatsappDispatchLog(
      recipientName: (data['recipientName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      messageType: (data['messageType'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'bookings',
      status: (data['status'] as String?) ?? 'sent',
      sentAt: sent is Timestamp ? sent.toDate() : null,
    );
  }
}

class WhatsappCreditPack {
  /// Metal name for the pack — Bronze / Silver / Gold. A proper noun,
  /// shown as-is in both languages, like the Pro / Business tier names.
  final String name;
  final int credits;
  final int price;

  /// Deck's stated unit price, kept as a string because `formatRs`
  /// drops fractions and the per-message price needs its decimals
  /// (Rs 5.00 / 4.75 / 4.00).
  final String perMessage;
  final bool bestValue;

  const WhatsappCreditPack({
    required this.name,
    required this.credits,
    required this.price,
    required this.perMessage,
    this.bestValue = false,
  });
}

const List<WhatsappCreditPack> whatsappCreditPacks = [
  WhatsappCreditPack(
      name: 'Bronze', credits: 50, price: 250, perMessage: '5.00'),
  WhatsappCreditPack(
      name: 'Silver', credits: 105, price: 499, perMessage: '4.75'),
  WhatsappCreditPack(
      name: 'Gold',
      credits: 250,
      price: 999,
      perMessage: '4.00',
      bestValue: true),
];

/// The named pack for a stored credits count (purchase requests store
/// the count, not the name). Returns null for an unknown count, so
/// callers keep showing the bare number instead of guessing.
WhatsappCreditPack? whatsappCreditPackForCredits(int credits) {
  for (final pack in whatsappCreditPacks) {
    if (pack.credits == credits) return pack;
  }
  return null;
}

int freeMonthlyCreditsForTier(String tier) {
  switch (tier) {
    case 'pro':
      return 30;
    case 'business':
      return 100;
    default:
      return 10;
  }
}

