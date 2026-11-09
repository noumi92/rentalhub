import '../../domain/entities/finance_settings_entity.dart';

class FinanceSettingsModel extends FinanceSettingsEntity {
  const FinanceSettingsModel({
    required super.shopId,
    super.currency,
    super.taxPercent,
    super.serviceChargePercent,
    super.paymentCash,
    super.paymentBankTransfer,
    super.paymentJazzCash,
    super.paymentEasyPaisa,
    super.autoSendReceipt,
  });

  factory FinanceSettingsModel.fromEntity(FinanceSettingsEntity e) {
    return FinanceSettingsModel(
      shopId: e.shopId,
      currency: e.currency,
      taxPercent: e.taxPercent,
      serviceChargePercent: e.serviceChargePercent,
      paymentCash: e.paymentCash,
      paymentBankTransfer: e.paymentBankTransfer,
      paymentJazzCash: e.paymentJazzCash,
      paymentEasyPaisa: e.paymentEasyPaisa,
      autoSendReceipt: e.autoSendReceipt,
    );
  }

  factory FinanceSettingsModel.fromMap(Map<String, dynamic> map) {
    return FinanceSettingsModel(
      shopId: map['shopId'] ?? '',
      currency: map['currency'] ?? 'PKR',
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
      serviceChargePercent:
          (map['serviceChargePercent'] as num?)?.toDouble() ?? 0,
      paymentCash: map['paymentCash'] != false,
      paymentBankTransfer: map['paymentBankTransfer'] != false,
      paymentJazzCash: map['paymentJazzCash'] == true,
      paymentEasyPaisa: map['paymentEasyPaisa'] == true,
      autoSendReceipt: map['autoSendReceipt'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'currency': currency,
      'taxPercent': taxPercent,
      'serviceChargePercent': serviceChargePercent,
      'paymentCash': paymentCash,
      'paymentBankTransfer': paymentBankTransfer,
      'paymentJazzCash': paymentJazzCash,
      'paymentEasyPaisa': paymentEasyPaisa,
      'autoSendReceipt': autoSendReceipt,
    };
  }
}
