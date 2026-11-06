import 'package:equatable/equatable.dart';

/// Phase B (H1): one money account of the shop — cash in hand, a
/// bank account, JazzCash or EasyPaisa. The balance is never
/// stored: it is the opening balance plus every transfer posted
/// to the account, so the ledger and the balance can never drift.
class FinanceAccountEntity extends Equatable {
  final String accountId;
  final String shopId;
  final String name;
  final String type; // 'cash' | 'bank' | 'jazzcash' | 'easypaisa'
  final int openingBalancePkr;
  final bool isDefault;

  const FinanceAccountEntity({
    required this.accountId,
    required this.shopId,
    required this.name,
    required this.type,
    this.openingBalancePkr = 0,
    this.isDefault = false,
  });

  FinanceAccountEntity copyWith({int? openingBalancePkr}) {
    return FinanceAccountEntity(
      accountId: accountId,
      shopId: shopId,
      name: name,
      type: type,
      openingBalancePkr: openingBalancePkr ?? this.openingBalancePkr,
      isDefault: isDefault,
    );
  }

  @override
  List<Object?> get props =>
      [accountId, shopId, name, type, openingBalancePkr, isDefault];
}
