import '../../domain/entities/finance_account_entity.dart';

class FinanceAccountModel extends FinanceAccountEntity {
  const FinanceAccountModel({
    required super.accountId,
    required super.shopId,
    required super.name,
    required super.type,
    super.openingBalancePkr,
    super.isDefault,
  });

  factory FinanceAccountModel.fromEntity(FinanceAccountEntity e) {
    return FinanceAccountModel(
      accountId: e.accountId,
      shopId: e.shopId,
      name: e.name,
      type: e.type,
      openingBalancePkr: e.openingBalancePkr,
      isDefault: e.isDefault,
    );
  }

  factory FinanceAccountModel.fromMap(Map<String, dynamic> map) {
    return FinanceAccountModel(
      accountId: map['accountId'] ?? '',
      shopId: map['shopId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'cash',
      openingBalancePkr: map['openingBalancePkr'] ?? 0,
      isDefault: map['isDefault'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'shopId': shopId,
      'name': name,
      'type': type,
      'openingBalancePkr': openingBalancePkr,
      'isDefault': isDefault,
    };
  }
}
