import '../../domain/entities/finance_category_entity.dart';

class FinanceCategoryModel extends FinanceCategoryEntity {
  const FinanceCategoryModel({
    required super.categoryId,
    required super.shopId,
    required super.kind,
    required super.code,
    required super.name,
    required super.createdAt,
  });

  factory FinanceCategoryModel.fromEntity(FinanceCategoryEntity e) {
    return FinanceCategoryModel(
      categoryId: e.categoryId,
      shopId: e.shopId,
      kind: e.kind,
      code: e.code,
      name: e.name,
      createdAt: e.createdAt,
    );
  }

  factory FinanceCategoryModel.fromMap(Map<String, dynamic> map) {
    return FinanceCategoryModel(
      categoryId: map['categoryId'] ?? '',
      shopId: map['shopId'] ?? '',
      kind: map['kind'] ?? 'expense',
      code: map['code'] ?? '',
      name: map['name'] ?? map['code'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'shopId': shopId,
      'kind': kind,
      'code': code,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
