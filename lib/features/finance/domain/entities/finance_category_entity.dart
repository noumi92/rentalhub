import 'package:equatable/equatable.dart';

/// Audit impl (O52): one income/expense category of a shop,
/// stored in `finance_categories`. `code` is the stable slug saved
/// on ledger entries (e.g. 'wash'); `name` is the display label
/// the owner can rename.
class FinanceCategoryEntity extends Equatable {
  final String categoryId;
  final String shopId;
  final String kind; // 'income' | 'expense'
  final String code;
  final String name;
  final DateTime createdAt;

  const FinanceCategoryEntity({
    required this.categoryId,
    required this.shopId,
    required this.kind,
    required this.code,
    required this.name,
    required this.createdAt,
  });

  FinanceCategoryEntity copyWith({String? name}) {
    return FinanceCategoryEntity(
      categoryId: categoryId,
      shopId: shopId,
      kind: kind,
      code: code,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [categoryId, shopId, kind, code, name, createdAt];
}
