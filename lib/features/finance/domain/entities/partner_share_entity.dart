import 'package:equatable/equatable.dart';

/// Phase B (H4): one partner's share of the shop — a percentage of
/// the profit, settled by hand. The share itself is a record; the
/// money moves through the ledger as an expense transfer.
class PartnerShareEntity extends Equatable {
  final String shareId;
  final String shopId;
  final String partnerName;
  final int sharePercent;
  final DateTime createdAt;

  const PartnerShareEntity({
    required this.shareId,
    required this.shopId,
    required this.partnerName,
    required this.sharePercent,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [shareId, shopId, partnerName, sharePercent, createdAt];
}
