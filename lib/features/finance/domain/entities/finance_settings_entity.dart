import 'package:equatable/equatable.dart';

/// Audit impl (O48): one shop's finance settings, stored as the
/// single document `finance_settings/{shopId}`. Currency is
/// display-only PKR (the app only trades in rupees); tax and service
/// charges are percentages the owner sets; payment methods are
/// toggles for which ways the shop accepts money; the receipt
/// toggle only records the preference — actual WhatsApp sending
/// still needs the WhatsApp Business setup (gate D2).
class FinanceSettingsEntity extends Equatable {
  final String shopId;
  final String currency;
  final double taxPercent;
  final double serviceChargePercent;
  final bool paymentCash;
  final bool paymentBankTransfer;
  final bool paymentJazzCash;
  final bool paymentEasyPaisa;
  final bool autoSendReceipt;

  const FinanceSettingsEntity({
    required this.shopId,
    this.currency = 'PKR',
    this.taxPercent = 0,
    this.serviceChargePercent = 0,
    this.paymentCash = true,
    this.paymentBankTransfer = true,
    this.paymentJazzCash = false,
    this.paymentEasyPaisa = false,
    this.autoSendReceipt = false,
  });

  FinanceSettingsEntity copyWith({
    String? shopId,
    double? taxPercent,
    double? serviceChargePercent,
    bool? paymentCash,
    bool? paymentBankTransfer,
    bool? paymentJazzCash,
    bool? paymentEasyPaisa,
    bool? autoSendReceipt,
  }) {
    return FinanceSettingsEntity(
      shopId: shopId ?? this.shopId,
      currency: currency,
      taxPercent: taxPercent ?? this.taxPercent,
      serviceChargePercent: serviceChargePercent ?? this.serviceChargePercent,
      paymentCash: paymentCash ?? this.paymentCash,
      paymentBankTransfer: paymentBankTransfer ?? this.paymentBankTransfer,
      paymentJazzCash: paymentJazzCash ?? this.paymentJazzCash,
      paymentEasyPaisa: paymentEasyPaisa ?? this.paymentEasyPaisa,
      autoSendReceipt: autoSendReceipt ?? this.autoSendReceipt,
    );
  }

  @override
  List<Object?> get props => [
        shopId,
        currency,
        taxPercent,
        serviceChargePercent,
        paymentCash,
        paymentBankTransfer,
        paymentJazzCash,
        paymentEasyPaisa,
        autoSendReceipt,
      ];
}
