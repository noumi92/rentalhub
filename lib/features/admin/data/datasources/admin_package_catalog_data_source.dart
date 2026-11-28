import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../owner/presentation/services/subscription_plans.dart';
import '../../../owner/presentation/services/whatsapp_credits_models.dart';
import '../../domain/admin_permissions.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_session.dart';

/// Editable Shop Subscription Package stored in `platform_settings/shop_packages`.
class AdminShopPackage {
  final String id;
  final String name;
  final int monthlyPrice;
  final int yearlyPrice;
  final int? carLimit;
  final int staffLimit;
  final int freeMonthlyCredits;
  final bool isActive;

  const AdminShopPackage({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.carLimit,
    required this.staffLimit,
    this.freeMonthlyCredits = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
        'carLimit': carLimit,
        'staffLimit': staffLimit,
        'freeMonthlyCredits': freeMonthlyCredits,
        'isActive': isActive,
      };

  factory AdminShopPackage.fromMap(Map<String, dynamic> map) => AdminShopPackage(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        monthlyPrice: (map['monthlyPrice'] as num?)?.toInt() ?? 0,
        yearlyPrice: (map['yearlyPrice'] as num?)?.toInt() ?? 0,
        carLimit: (map['carLimit'] as num?)?.toInt(),
        staffLimit: (map['staffLimit'] as num?)?.toInt() ?? 1,
        freeMonthlyCredits: (map['freeMonthlyCredits'] as num?)?.toInt() ?? 0,
        isActive: (map['isActive'] as bool?) ?? true,
      );
}

/// Editable WhatsApp Credit Package stored in `platform_settings/whatsapp_packages`.
class AdminWhatsappPackage {
  final String id;
  final String name;
  final int credits;
  final int price;
  final bool bestValue;
  final bool isActive;

  const AdminWhatsappPackage({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    this.bestValue = false,
    this.isActive = true,
  });

  String get perMessage =>
      credits <= 0 ? '0.00' : (price / credits).toStringAsFixed(2);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'credits': credits,
        'price': price,
        'bestValue': bestValue,
        'isActive': isActive,
      };

  factory AdminWhatsappPackage.fromMap(Map<String, dynamic> map) =>
      AdminWhatsappPackage(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        credits: (map['credits'] as num?)?.toInt() ?? 0,
        price: (map['price'] as num?)?.toInt() ?? 0,
        bestValue: (map['bestValue'] as bool?) ?? false,
        isActive: (map['isActive'] as bool?) ?? true,
      );
}

/// Firestore CRUD for Shop Subscription Packages and WhatsApp Credit Packages.
/// Persisted in `platform_settings/shop_packages` and `platform_settings/whatsapp_packages`
/// (readable by signed-in users, writable by `isAdminOps()`).
class AdminPackageCatalogDataSource {
  AdminPackageCatalogDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _fs {
    if (_firestore != null) return _firestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static List<AdminShopPackage> defaultShopPackages() => subscriptionPlans
      .map((p) => AdminShopPackage(
            id: p.id,
            name: '${p.id[0].toUpperCase()}${p.id.substring(1)}',
            monthlyPrice: p.monthlyPrice,
            yearlyPrice: p.yearlyTotal,
            carLimit: p.carLimit,
            staffLimit: p.staffLimit,
            freeMonthlyCredits: freeMonthlyCreditsForTier(p.id),
          ))
      .toList();

  static List<AdminWhatsappPackage> defaultWhatsappPackages() =>
      whatsappCreditPacks
          .map((p) => AdminWhatsappPackage(
                id: p.name.toLowerCase(),
                name: p.name,
                credits: p.credits,
                price: p.price,
                bestValue: p.bestValue,
              ))
          .toList();

  Future<List<AdminShopPackage>> getShopPackages() async {
    final fs = _fs;
    if (fs == null) return defaultShopPackages();
    try {
      final doc =
          await fs.collection('platform_settings').doc('shop_packages').get();
      final raw = doc.data()?['items'];
      if (raw is List && raw.isNotEmpty) {
        return raw
            .whereType<Map>()
            .map((m) => AdminShopPackage.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return defaultShopPackages();
    } catch (_) {
      return defaultShopPackages();
    }
  }

  Future<List<AdminWhatsappPackage>> getWhatsappPackages() async {
    final fs = _fs;
    if (fs == null) return defaultWhatsappPackages();
    try {
      final doc = await fs
          .collection('platform_settings')
          .doc('whatsapp_packages')
          .get();
      final raw = doc.data()?['items'];
      if (raw is List && raw.isNotEmpty) {
        return raw
            .whereType<Map>()
            .map((m) =>
                AdminWhatsappPackage.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
      return defaultWhatsappPackages();
    } catch (_) {
      return defaultWhatsappPackages();
    }
  }

  Future<bool> saveShopPackage(
    AdminShopPackage pkg, {
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _fs;
    if (fs == null) return false;
    try {
      final current = await getShopPackages();
      final idx = current.indexWhere((p) => p.id == pkg.id);
      if (idx >= 0) {
        current[idx] = pkg;
      } else {
        current.add(pkg);
      }
      await fs.collection('platform_settings').doc('shop_packages').set({
        'items': current.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: idx >= 0 ? 'shop_package_updated' : 'shop_package_created',
        targetType: 'package',
        targetId: pkg.id,
        detail: '${pkg.name} (Rs. ${pkg.monthlyPrice}/mo)',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteShopPackage(String id, {String? adminRole}) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _fs;
    if (fs == null) return false;
    try {
      final current = await getShopPackages();
      current.removeWhere((p) => p.id == id);
      await fs.collection('platform_settings').doc('shop_packages').set({
        'items': current.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: 'shop_package_deleted',
        targetType: 'package',
        targetId: id,
        detail: 'Removed shop package $id',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveWhatsappPackage(
    AdminWhatsappPackage pkg, {
    String? adminRole,
  }) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _fs;
    if (fs == null) return false;
    try {
      final current = await getWhatsappPackages();
      final idx = current.indexWhere((p) => p.id == pkg.id);
      if (idx >= 0) {
        current[idx] = pkg;
      } else {
        current.add(pkg);
      }
      await fs.collection('platform_settings').doc('whatsapp_packages').set({
        'items': current.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action:
            idx >= 0 ? 'whatsapp_package_updated' : 'whatsapp_package_created',
        targetType: 'package',
        targetId: pkg.id,
        detail: '${pkg.name} (${pkg.credits} credits, Rs. ${pkg.price})',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteWhatsappPackage(String id, {String? adminRole}) async {
    if (!await AdminSession.currentAdminCan(
        AdminPermission.manageSubscriptions,
        adminRole: adminRole)) {
      return false;
    }
    final fs = _fs;
    if (fs == null) return false;
    try {
      final current = await getWhatsappPackages();
      current.removeWhere((p) => p.id == id);
      await fs.collection('platform_settings').doc('whatsapp_packages').set({
        'items': current.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AdminAuditService.logAction(
        action: 'whatsapp_package_deleted',
        targetType: 'package',
        targetId: id,
        detail: 'Removed WhatsApp package $id',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
